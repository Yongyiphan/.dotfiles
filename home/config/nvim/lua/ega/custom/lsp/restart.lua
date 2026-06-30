-- This module re-exports restart functions from utils.lua for LSP restart commands
local utils = require("ega.custom.lsp.utils")
return {
  restart_attached = utils.restart_attached,
  restart_by_name = utils.restart_by_name,
}
