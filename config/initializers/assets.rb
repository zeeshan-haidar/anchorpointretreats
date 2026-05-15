# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'webfonts')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( *.woff2 *.woff Lora/Lora-Regular.woff2 Lora/Lora-Regular.woff InterTight/InterTight-Regular.woff2 InterTight/InterTight-Regular.woff fa-solid-900.woff2 fa-brands-400.woff2 fa-regular-400.woff2 fa-v4compatibility.woff2 )
