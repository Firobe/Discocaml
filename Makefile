all:
	dune build @install

install: all
	dune install

doc:
	dune build @doc

clean:
	dune clean
