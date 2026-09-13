vim.opt.number = true

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,

		config = function()
			require("catppuccin").setup({
				flavour = "macchiato",
			})

			vim.cmd.colorscheme("catppuccin")
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",

		config = function()
			local ts = require("nvim-treesitter")

			ts.install({
				"lua",
				"qmljs",
				"bash",
				"fish",
				"json",
				"regex",
				"markdown",
				"markdown_inline",
			})

			-- QML-Dateien benutzen den qmljs-Parser
			vim.treesitter.language.register("qmljs", "qml")
		end,
	},

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,

		opts = {
			picker = {
				enabled = true,
			},
		},
	},
	{
		"stevearc/conform.nvim",

		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				qml = { "qmlformat" },

				c = { "clang_format" },
				cpp = { "clang_format" },
			},

			formatters = {
				qmlformat = {
					command = "/usr/lib64/qt6/bin/qmlformat",
				},
			},

			format_on_save = {
				timeout_ms = 1000,
				lsp_format = "fallback",
			},
		},
	},
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"lua",
		"qml",
		"bash",
		"fish",
		"json",
		"markdown",
	},

	callback = function()
		vim.treesitter.start()
	end,
})

vim.keymap.set("n", "<leader><space>", function()
	Snacks.picker.files()
end, { desc = "Dateien suchen" })

vim.keymap.set("n", "<leader>fg", function()
	Snacks.picker.grep()
end, { desc = "Text suchen" })

vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Offene Buffer" })

vim.keymap.set("n", "<leader>fc", function()
	Snacks.picker.files({
		cwd = vim.fn.expand("~/.config"),
		hidden = true,
	})
end, { desc = "Config-Dateien" })

-- C / C++ LSP
vim.lsp.config("clangd", {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
	},

	filetypes = {
		"c",
		"cpp",
	},

	root_markers = {
		".clangd",
		"compile_commands.json",
		"compile_flags.txt",
		".git",
	},
})
-- C++: aktuelle Datei bauen und ausführen
vim.keymap.set("n", "<leader>br", function()
	vim.cmd("write")

	local source = vim.fn.expand("%:p")
	local output = vim.fn.expand("%:p:r")

	local command = "g++ -std=c++23 -Wall -Wextra -pedantic "
		.. vim.fn.shellescape(source)
		.. " -o "
		.. vim.fn.shellescape(output)
		.. " && "
		.. vim.fn.shellescape(output)

	vim.cmd("botright split | terminal " .. command)
end, { desc = "Build & Run C++" })

vim.lsp.enable("clangd")

-- Keine Inline-/Ghost-Vorschläge
vim.lsp.inline_completion.enable(false)

-- Keine eingeblendeten Parameter-/Typ-Hinweise im Code
vim.lsp.inlay_hint.enable(false)

-- LSP-Tastenbelegung
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local opts = { buffer = args.buf }

		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	end,
})

vim.keymap.set("n", "<leader>t", function()
	vim.cmd("botright split | terminal")
end, { desc = "Terminal unten öffnen" })

-- Aus Terminal-Splits direkt zu anderen Neovim-Fenstern wechseln
vim.keymap.set("t", "<C-w>k", [[<C-\><C-n><C-w>k]])
vim.keymap.set("t", "<C-w>j", [[<C-\><C-n><C-w>j]])
vim.keymap.set("t", "<C-w>h", [[<C-\><C-n><C-w>h]])
vim.keymap.set("t", "<C-w>l", [[<C-\><C-n><C-w>l]])
