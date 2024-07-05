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
  // If there's a Shoes-Spec script, make sure it gets loaded before the
  // apps.
  const tag = document.querySelector('script[type="text/shoes-spec"]');
  if(tag) {
    vm.eval(`
      test_elt = JS.global[:document].querySelector('script[type="text/shoes-spec"]')
      test_code = test_elt[:innerText]
      Shoes::Spec.instance.run_shoes_spec_test_code test_code
    `);
  }

  const tags = document.querySelectorAll('script[type="text/ruby"]');

  // Get Ruby scripts in parallel.
  const promisingRubyScripts = Array.from(tags).map((tag) =>
    loadScriptAsync(tag),
  );

  // Run Ruby scripts sequentially.
  for await (const script of promisingRubyScripts) {
    if (script) {
      const { scriptContent, evalStyle } = script;
      vm.eval(scriptContent);
      break;
    }
  }

}

async function loadScriptAsync(tag) {
  const evalStyle = "sync";
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
