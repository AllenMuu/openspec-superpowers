# Install guide

This repository hosts multiple OpenSpec schema bundles. Pick the bridge you want, then install via either method below.

## Method 1: Claude Code one-shot prompt (recommended)

Open Claude Code in your project root and paste this prompt (substitute `<bridge-name>` with `superpowers-bridge` or another bridge):

```
Install the <bridge-name> schema for OpenSpec into this project:

1. Verify the project has an `openspec/` directory (run `openspec init` if missing).
2. Clone https://github.com/JiangWay/openspec-schemas to a temp dir.
3. Copy the `<bridge-name>/` subdirectory to `openspec/schemas/<bridge-name>/`.
4. Run `openspec schema validate <bridge-name>` to verify.
5. Run `openspec schemas` and confirm `<bridge-name>` is listed.
6. Clean up the temp directory.
7. If the bridge requires the Superpowers plugin, verify it's installed
   by running `claude plugin list`. If not listed, run
   `claude plugin install superpowers@claude-plugins-official`.
8. Show me the final state.
```

Claude will execute the install end-to-end, including any per-bridge dependencies.

## Method 2: Manual bash (CI / non-Claude environments)

```bash
# Replace <bridge-name>
BRIDGE=superpowers-bridge
git clone https://github.com/JiangWay/openspec-schemas /tmp/oss
cp -R /tmp/oss/$BRIDGE ~/your-project/openspec/schemas/$BRIDGE
rm -rf /tmp/oss
cd ~/your-project
openspec schema validate $BRIDGE
openspec schemas
```

For Superpowers-dependent bridges:

```bash
claude plugin install superpowers@claude-plugins-official
```

## Verify

After install, in your project root:

```bash
openspec schemas       # Should list the new schema as "(project)"
openspec schema validate <bridge-name>  # Should print ✓ valid
```

To use the new schema for a change:

```bash
/opsx:new my-feature --schema <bridge-name>
```
