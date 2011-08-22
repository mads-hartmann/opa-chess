OPA=opa
EXE=chess.exe

all: $(EXE)

chess.exe:
	opa src/page.opa src/networkwrapper.opa src/chat.opa src/board.opa src/column.opa src/game.opa src/main.opa src/position.opa src/types.opa src/user.opa -o $(EXE)

run:
	./$(EXE)

clean:
	rm -rf _build _tracks
	rm -rf *.exe
	rm -rf *.log
	rm -rf *.opp
	rm -rf *.opx
	rm -rf *.opx.broken

