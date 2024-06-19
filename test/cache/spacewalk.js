// Do we have to match the wasm-wasi JS version here with the ruby.wasm
// version we used to build the Wasm package below?
import { DefaultRubyVM } from "https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.6.0/dist/browser/+esm";

// For Locally-compiled Ruby.wasm VM:
const response = await fetch("./packed_ruby.wasm");
const module = await WebAssembly.compile(await response.arrayBuffer());

const { vm } = await DefaultRubyVM(module);

window.rubyVM = vm;

// Some code copied from browser.script.ts in ruby.wasm by Yuta Saito

vm.eval(`
  require "/bundle/setup"
  require "js" # Needed even with /bundle/setup
  $LOAD_PATH.unshift "/spaceshoes_lib"
  require "space_shoes/core"
  require "scarpe/space_shoes" # Scarpe display service for SpaceShoes
`);

async function runShoesApps(vm) {
  const tags = document.querySelectorAll('script[type="text/ruby"]');

  // Get Ruby scripts in parallel.
  const promisingRubyScripts = Array.from(tags).map((tag) =>
    loadScriptAsync(tag),
  );

  // Run Ruby scripts sequentially.
  for await (const script of promisingRubyScripts) {
    if (script) {
      const { scriptContent, evalStyle } = script;
      switch (evalStyle) {
        case "async":
          vm.evalAsync(scriptContent);
          break;
        case "sync":
          vm.eval(scriptContent);
          break;
      }
    }
  }
}

function deriveEvalStyle(tag) {
  const rawEvalStyle = tag.getAttribute("data-eval") || "sync";
  if (rawEvalStyle !== "async" && rawEvalStyle !== "sync") {
    console.warn(
      `data-eval attribute of script tag must be "async" or "sync". ${rawEvalStyle} is ignored and "sync" is used instead.`,
    );
    return "sync";
  }
  return rawEvalStyle;
};

async function loadScriptAsync(tag) {
  const evalStyle = deriveEvalStyle(tag);
  if (tag.hasAttribute("src")) {
    const url = tag.getAttribute("src");
    const response = await fetch(url);

    if (response.ok) {
      return { scriptContent: await response.text(), evalStyle };
    }

    return Promise.resolve(null);
  }

  return Promise.resolve({ scriptContent: tag.innerHTML, evalStyle });
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () =>
    runShoesApps(vm),
  );
} else {
  runShoesApps(vm);
}
