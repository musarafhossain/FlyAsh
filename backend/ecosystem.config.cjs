// PM2 process file for the VPS. The app runs from the compiled build/ folder;
// deploy/deploy.sh copies backend/.env into build/.env before (re)starting.
//   pm2 start ecosystem.config.cjs && pm2 save
module.exports = {
  apps: [
    {
      name: 'flyash-api',
      cwd: __dirname + '/build',
      script: 'bin/server.js',
      exec_mode: 'fork',
      instances: 1,
      max_memory_restart: '300M',
      env: { NODE_ENV: 'production' },
    },
  ],
}
