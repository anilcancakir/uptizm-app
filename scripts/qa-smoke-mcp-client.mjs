#!/usr/bin/env node
/**
 * Minimal JSON-RPC stdio client for the ai-test MCP server.
 * Usage: node qa-smoke-mcp-client.mjs <tool-name> <json-args> <server-path>
 * Exits 0, prints result JSON to stdout on success.
 * Exits 1 with diagnostic to stderr on failure.
 */

import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';

const [, , toolName, jsonArgs, serverPath] = process.argv;

if (!toolName || !jsonArgs || !serverPath) {
    console.error('usage: node qa-smoke-mcp-client.mjs <tool-name> <json-args> <server-path>');
    process.exit(1);
}

let toolArgs;
try {
    toolArgs = JSON.parse(jsonArgs);
} catch {
    console.error(`[mcp-client] invalid json-args: ${jsonArgs}`);
    process.exit(1);
}

// Resolve tsx from node_modules beside the server entry.
const serverDir = serverPath.replace(/\/src\/cli\.ts$/, '');
const tsxBin = `${serverDir}/node_modules/.bin/tsx`;

const serverProc = spawn(tsxBin, [serverPath], {
    stdio: ['pipe', 'pipe', 'inherit'],
    env: { ...process.env },
});

serverProc.on('error', (err) => {
    console.error(`[mcp-client] failed to spawn server: ${err.message}`);
    process.exit(1);
});

const rl = createInterface({ input: serverProc.stdout });
const pending = new Map();
let reqId = 1;

const frame = (method, params) =>
    JSON.stringify({ jsonrpc: '2.0', id: reqId++, method, params });

function send(f) {
    return new Promise((resolve, reject) => {
        const id = JSON.parse(f).id;
        pending.set(id, { resolve, reject });
        serverProc.stdin.write(f + '\n');
    });
}

rl.on('line', (line) => {
    if (!line.trim()) return;
    let msg;
    try { msg = JSON.parse(line); } catch { return; }
    if (msg.id !== undefined) {
        const entry = pending.get(msg.id);
        if (entry) {
            pending.delete(msg.id);
            msg.error
                ? entry.reject(new Error(msg.error.message ?? JSON.stringify(msg.error)))
                : entry.resolve(msg.result);
        }
    }
});

rl.on('close', () => {
    for (const [, e] of pending) e.reject(new Error('[mcp-client] server stdout closed'));
});

async function run() {
    // 1. MCP handshake.
    await send(frame('initialize', {
        protocolVersion: '2024-11-05',
        capabilities: {},
        clientInfo: { name: 'qa-smoke-client', version: '1.0.0' },
    }));

    // 2. Notify initialized (required by MCP 2024-11-05 spec).
    serverProc.stdin.write(
        JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} }) + '\n',
    );

    // 3. Call the requested tool and emit result.
    const result = await send(frame('tools/call', { name: toolName, arguments: toolArgs }));
    process.stdout.write(JSON.stringify(result) + '\n');

    serverProc.stdin.end();
    serverProc.kill('SIGTERM');
    process.exit(0);
}

run().catch((err) => {
    console.error(`[mcp-client] error: ${err.message}`);
    serverProc.stdin.end();
    serverProc.kill('SIGTERM');
    process.exit(1);
});
