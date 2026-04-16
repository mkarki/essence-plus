const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding vouchers...');

  // Generate 20 sample vouchers
  const partners = ['Shell', 'TotalEnergies', 'Afriquia', 'Winxo'];
  const values = [20, 30, 50];

  const vouchers = [];
  for (let i = 0; i < 20; i++) {
    const partner = partners[i % partners.length];
    const value = values[i % values.length];
    const code = `ESS-${uuidv4().substring(0, 8).toUpperCase()}`;

    vouchers.push({
      code,
      valueAmount: value,
      currency: 'MAD',
      stationPartner: partner,
      status: 'available',
      expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90 days
    });
  }

  await prisma.voucher.createMany({ data: vouchers });

  console.log(`Created ${vouchers.length} vouchers`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
