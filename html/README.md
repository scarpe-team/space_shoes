# Templates and Experiments in HTML and Wasm

To serve these, the following is normally needed from inside the html directory:

    bundle exec ruby -run -e httpd -- -p 4321 .

Then you can point your browser at a URL like "http://localhost:4321/templates/custom_ruby_wasm.html".

If you haven't built the default Wasm package, you'll need to do that with something like "./exe/space-shoes --dev build-default".
