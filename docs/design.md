# Answercast Phoenix Live View Prototype

Reimplement the Answercast Google Cast android/ios apps as a pure webapp using Phoenix Live View and OTP Processes.

## Overall design

As this will be a purely web-based implementation, the server will handle all of the communications between players and the game manager process. Users will create a new game which will have an assigned short-code 4 characters long. Other players or viewers can join this game by that shortcode.

### Player

A player is a participating client in the game. They will enter a Name and join the game. On each round they will provide their answer along with the other players. In this version they will also be able to see the state of the game on their own device, such as the Scoreboard and Resultboard

### Viewer

A viewer will be a non-player client that just views the state of the game. This will be the same as the Google Cast receiver in the old version. Most of the time this will be a display for the players to look at to see the state of the game... both the Scoreboard and Resultboards. Viewers will be allowed to have 0 interaction with the game. Eventually a Google Cast receiver can be directed to this kind of view by a Player.

## Technical design

The entire application is implemented with Elixir/Phoenix and the front-end is driven by Phoenix Live View for each client.

### Game

A game is comprised of the following state:

- Settings: e.g. A round timer, whether to show player names on answers, if duplicates are allowed, etc, etc. This will be an ever expanding list of options as new features are added, but in the beginning will be very simple.
- Players: The list of current players. As devices (phones) are turned on and off the connections will be in a constant state of flux and constantly being lost (especially ios). So the current list of Players will be based on name, and only timeout if a client doesn't reconnect before the timeout (setting).
- State: A basic state machine, such as Results, Polling, etc. The exact states will depend on settings.

### Game code

Each game will get a 4-digit code to uniquely identify it.

- Case insensitive
- Always stored and shown in uppercase
- A-Z except I, O
- 2-9 (no 0, 1)

This gives 32^4 possible permutations, or 1,048,576 possible concurrent games.

### Game Manager

A Game Manager is a GenServer that is created for each game to store the state of that game and act as a state machine. It communicates with the players/viewers (clients) via regular process messages. The individual Game Managers are ephemeral and will only be running while there are clients connected. The state of the game will be persisted to database on a regular basis, so that if the server crashes, the first client to reconnect will relaunch the manager.

### Game Supervisor

A DynamicSupervisor process that tracks the Game Manager GenServers by their short code. If there isn't a running game for the code, will spawn a new Game Manager with that code.
