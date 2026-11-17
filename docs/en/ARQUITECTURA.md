# Architecture

[Español](../ARQUITECTURA.md) · [English](ARQUITECTURA.md) · [Français](../fr/ARQUITECTURA.md) · [Index](README.md)

React and TypeScript consume a same-origin API. Nginx and Web Gateway connect to IRIS:

`Rugby.API.REST → HTTP.In → API.Process → Business Operation → services → persistent models`.

Entities store versioned JSON documents isolated by game. JWT identifies the user and `X-Game-Id` selects the game; the server validates ownership and permissions. Player match analytics also use compact columnar projections.

Writes use locks, transactions and retry keys. The match worker commits states, events and commands independently of the browser. Seeds reproduce simulations; changing speed does not alter sporting random draws.

Code: `../../iris/src`, `../../rugby-frontend/src` and `../../webgateway`. There is no multiplayer mode or complete physics simulation.
