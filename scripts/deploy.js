// scripts/deploy.js
async function main() {
  // 1. Get the contract to deploy
  const MathLaunchPad = await ethers.getContractFactory('MathLaunchPad');
  console.log('Deploying MathLaunchPad...');
  const mathLaunchPad = await MathLaunchPad.deploy('MathLaunchPad', 'MATH', 200);
  await mathLaunchPad.deployed();
  console.log('MathLaunchPad deployed to:', mathLaunchPad.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
     console.error(error);
     process.exit(1);
  });