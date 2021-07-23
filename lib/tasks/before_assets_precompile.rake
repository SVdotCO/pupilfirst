desc 'Prepare application for asset precompilation'
task before_assets_precompile: [:environment] do
  puts 'Generating the locales.json file...'
  system('bundle exec i18n export')

  puts 'Compiling ReScript files...'
  system('yarn re:build')
end

Rake::Task['assets:precompile'].enhance ['before_assets_precompile']
