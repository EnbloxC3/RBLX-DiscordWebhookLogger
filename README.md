# RBLX Discord Webhook Logger

A simple and efficient Roblox script that logs player joins and leaves to a Discord webhook.

## Requirements

- Roblox Studio (i guess u have)
- A Discord webhook URL
- HTTP requests enabled in your Roblox game [learn how to enable HTTP requests](https://create.roblox.com/docs/tr-tr/cloud-services/http-service)
- A Roblox game

## Placement

```text
Game/
├── ...
├── ServerScriptService/
│   ├── Logging.luau <---
│   ├── Region.luau <---
│   ├── ...
└── ...
```

## Configuration

In [Logging.luau](src/Game/ServerScriptService/Logging.luau):

```lua
...
-- Webhook URL
local WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL" -- replace with your actual webhook URL

-- Config
local RETRY_ON_FAILURE = false -- set to true to retry failed requests, otherwise failed requests will be dropped (i not recommended this cause of ratelimits and infinite loops)
local RETRY_DELAY = 5.0 -- delay in seconds before retrying a failed request (only used if RETRY_ON_FAILURE is true)
local REQUEST_INTERVAL = 1.0 -- minimum interval in seconds between requests to avoid hitting rate limits
local MAX_QUEUE = 200 -- maximum number of messages to queue before dropping new messages
...
```

## Usage

Just copy `src/Game/ServerScriptService/` content to your game's `ServerScriptService` and replace the `WEBHOOK_URL` variable with your actual Discord webhook URL. The script will automatically log player joins and leaves to the specified webhook. You can see log embeds in your Discord channel whenever a player joins or leaves the game.

## Develop Ideas

- Add more events to log (e.g., player deaths, chat messages, etc.)
- Implement a more robust retry mechanism for failed requests
- Add support for custom embed colors and formatting
- Another variants for other webhook platforms
- Add a configuration module for easier customization without modifying the main script (im lazy)

---

<!-- Repo Info -->

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/EnbloxC3/RBLX-DiscorWebhookLogger)
![GitHub repo size](https://img.shields.io/github/repo-size/EnbloxC3/RBLX-DiscorWebhookLogger)
![GitHub repo file or directory count](https://img.shields.io/github/directory-file-count/EnbloxC3/RBLX-DiscorWebhookLogger)
