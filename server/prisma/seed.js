const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');

const prisma = new PrismaClient();

/**
 * Distribution designed so most players hit a small voucher frequently,
 * and the big one is rare enough to stay exciting.
 *
 *   5 MAD  × 80   (≈66% of the pool)
 *  20 MAD  × 30   (≈25%)
 *  50 MAD  × 10   (≈ 8%)
 *
 * Run `npm run db:seed` whenever you want to top up the pool. Duplicate
 * codes are skipped because of the UNIQUE constraint.
 */
async function main() {
  const partners = ['Shell', 'TotalEnergies', 'Afriquia', 'Winxo'];
  const tiers = [
    { value: 5, count: 80 },
    { value: 20, count: 30 },
    { value: 50, count: 10 },
  ];

  const vouchers = [];
  for (const tier of tiers) {
    for (let i = 0; i < tier.count; i++) {
      const partner = partners[(i + tier.value) % partners.length];
      const code = `ESS${tier.value}-${uuidv4().substring(0, 8).toUpperCase()}`;
      vouchers.push({
        code,
        valueAmount: tier.value,
        currency: 'MAD',
        stationPartner: partner,
        status: 'available',
        expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
      });
    }
  }

  const result = await prisma.voucher.createMany({
    data: vouchers,
    skipDuplicates: true,
  });

  console.log(`Seeded ${result.count} voucher(s) across tiers.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
