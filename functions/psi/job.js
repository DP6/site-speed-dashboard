const { runJob } = require('./index');

console.log('PSI Job started');

runJob()
  .then(() => {
    console.log('PSI Job finished successfully');
    process.exit(0);
  })
  .catch((err) => {
    console.error('PSI Job failed:', err);
    process.exit(1);
  });
