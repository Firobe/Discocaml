# Discocaml

**Discocaml** is a library providing OCaml bindings to the Discord client API. It is
currently quite experimental and a work in progress. Feedback is welcome.

## Installation

Discocaml depends on the following libraries: `atdgen cohttp-lwt-unix websocket-lwt extlib`  
Furthermore, it uses `dune` as a build system.  

- Install the `opam` package providing by your distribution and run `opam init`
- Run `opam install dune atdgen cohttp-lwt-unix websocket-lwt extlib`
- Run `make && make install`

## Documentation

The latest version is available [here](https://firobe.fr/discocaml)  

`dune` requires the `odoc` program to generate the documentation
- Run `opam install odoc`
- Then `make doc`. The documentation can then be found in
  `_build/default/_doc/_html/index.html`

Furthermore, a running example is available in `examples/`. It can be built and
run using `make && make run` provided that a `token` file containing your bot
token is present is the directory.
