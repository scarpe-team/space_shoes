# Directories under space_shoes/lib

SpaceShoes runs in both guest and host configurations. It has capabilities like packaging or running an HTTP server which occur on the host, and capabilities like creating buttons that occur inside the browser, on the guest.

The lib/space_shoes directory mostly contains host-side code, but also a few shared files like lib/space_shoes/version.rb and lib/space_shoes/core.rb for error classes, the top-level module and similar.

The lib/scarpe/space_shoes.rb file is the Scarpe display service for the SpaceShoes library. It's used in the guest environment but not the host.

