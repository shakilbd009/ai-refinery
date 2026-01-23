#!/usr/bin/env node

/**
 * update-registry.js
 * Manages ideas-registry.json updates
 *
 * Usage:
 *   node update-registry.js add <id> <name>
 *   node update-registry.js update <id> <stage>
 *   node update-registry.js remove <id>
 *   node update-registry.js archive <id> <reason>
 */

const fs = require('fs');
const path = require('path');

const REGISTRY_PATH = path.join(__dirname, '..', 'ideas', 'ideas-registry.json');

// Load registry
function loadRegistry() {
  try {
    const data = fs.readFileSync(REGISTRY_PATH, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('Error loading registry:', error.message);
    process.exit(1);
  }
}

// Save registry
function saveRegistry(registry) {
  try {
    fs.writeFileSync(REGISTRY_PATH, JSON.stringify(registry, null, 2) + '\n', 'utf8');
  } catch (error) {
    console.error('Error saving registry:', error.message);
    process.exit(1);
  }
}

// Get current ISO date
function now() {
  return new Date().toISOString();
}

// Commands
const commands = {
  add(id, name) {
    const registry = loadRegistry();

    // Check if idea already exists
    const exists = registry.ideas.find(idea => idea.id === id);
    if (exists) {
      console.error(`Error: Idea "${id}" already exists`);
      process.exit(1);
    }

    const newIdea = {
      id,
      name,
      currentStage: '01-raw',
      createdAt: now(),
      lastUpdated: now()
    };

    registry.ideas.push(newIdea);
    saveRegistry(registry);

    console.log(`✓ Added idea: ${name}`);
    console.log(JSON.stringify(newIdea, null, 2));
  },

  update(id, stage) {
    const registry = loadRegistry();

    const idea = registry.ideas.find(i => i.id === id);
    if (!idea) {
      console.error(`Error: Idea "${id}" not found`);
      process.exit(1);
    }

    idea.currentStage = stage;
    idea.lastUpdated = now();

    saveRegistry(registry);

    console.log(`✓ Updated idea: ${idea.name}`);
    console.log(`  Stage: ${stage}`);
  },

  remove(id) {
    const registry = loadRegistry();

    const index = registry.ideas.findIndex(i => i.id === id);
    if (index === -1) {
      console.error(`Error: Idea "${id}" not found`);
      process.exit(1);
    }

    const removed = registry.ideas.splice(index, 1)[0];
    saveRegistry(registry);

    console.log(`✓ Removed idea: ${removed.name}`);
  },

  archive(id, reason = 'graduated') {
    const registry = loadRegistry();

    const index = registry.ideas.findIndex(i => i.id === id);
    if (index === -1) {
      console.error(`Error: Idea "${id}" not found`);
      process.exit(1);
    }

    const idea = registry.ideas.splice(index, 1)[0];

    if (!registry.archived) {
      registry.archived = [];
    }

    registry.archived.push({
      id: idea.id,
      name: idea.name,
      archivedAt: now(),
      reason,
      finalStage: idea.currentStage
    });

    saveRegistry(registry);

    console.log(`✓ Archived idea: ${idea.name}`);
    console.log(`  Reason: ${reason}`);
  },

  list() {
    const registry = loadRegistry();

    console.log('Active Ideas:');
    console.log('=============\n');

    if (registry.ideas.length === 0) {
      console.log('No active ideas.\n');
    } else {
      registry.ideas.forEach(idea => {
        console.log(`${idea.name} (${idea.id})`);
        console.log(`  Stage: ${idea.currentStage}`);
        console.log(`  Created: ${idea.createdAt}`);
        console.log(`  Updated: ${idea.lastUpdated}`);
        console.log('');
      });
    }

    if (registry.archived && registry.archived.length > 0) {
      console.log('\nArchived Ideas:');
      console.log('===============\n');

      registry.archived.forEach(idea => {
        console.log(`${idea.name} (${idea.id})`);
        console.log(`  Reason: ${idea.reason}`);
        console.log(`  Archived: ${idea.archivedAt}`);
        console.log('');
      });
    }
  }
};

// Main
const [,, command, ...args] = process.argv;

if (!command || command === 'help') {
  console.log(`
Usage: update-registry.js <command> [args]

Commands:
  add <id> <name>         Add new idea to registry
  update <id> <stage>     Update idea's current stage
  remove <id>             Remove idea from registry
  archive <id> [reason]   Archive idea (reasons: graduated, abandoned, duplicate)
  list                    List all ideas
  help                    Show this help

Examples:
  node update-registry.js add task-manager "Task Manager"
  node update-registry.js update task-manager 04-refine-l1
  node update-registry.js archive task-manager graduated
  node update-registry.js list
  `);
  process.exit(0);
}

if (!commands[command]) {
  console.error(`Error: Unknown command "${command}"`);
  console.log('Run "update-registry.js help" for usage');
  process.exit(1);
}

commands[command](...args);
