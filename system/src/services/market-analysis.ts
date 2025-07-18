/**
 * Professional Market Analysis Service for Algeria Real Estate
 * 
 * Provides comprehensive market intelligence for professional real estate agents including:
 * - Price trend analysis and forecasting
 * - Neighborhood analytics and scoring
 * - Investment analysis and ROI calculations
 * - Market positioning and competitive analysis
 * - Location intelligence and amenity scoring
 * - Professional insights and recommendations
 */

import { PrismaClient } from '@prisma/client';
import { calculateSimilarity } from './score-generator';

const prisma = new PrismaClient();

// Algeria-specific market data and configurations
export const ALGERIA_MARKET_DATA = {
  // Average price per sqm by wilaya (DZD) - 2024 market data
  avgPricePerSqm: {
    'Algiers': 180000,
    'Oran': 120000,
    'Constantine': 95000,
    'Annaba': 85000,
    'Blida': 140000,
    'Batna': 75000,
    'Djelfa': 65000,
    'Sétif': 80000,
    'Sidi Bel Abbès': 70000,
    'Biskra': 60000,
    'Tébessa': 55000,
    'El Oued': 50000,
    'Skikda': 75000,
    'Tiaret': 60000,
    'Béjaïa': 90000,
    'Tlemcen': 85000,
    'Ouargla': 65000,
    'Bouira': 70000,
    'Tizi Ouzou': 110000,
    'Médéa': 75000
  },
  
  // Market growth rates by wilaya (annual %)
  growthRates: {
    'Algiers': 0.08,
    'Oran': 0.06,
    'Constantine': 0.05,
    'Annaba': 0.04,
    'Blida': 0.07,
    'Batna': 0.03,
    'Djelfa': 0.02,
    'Sétif': 0.04,
    'Sidi Bel Abbès': 0.03,
    'Biskra': 0.02,
    'Tébessa': 0.02,
    'El Oued': 0.01,
    'Skikda': 0.03,
    'Tiaret': 0.02,
    'Béjaïa': 0.05,
    'Tlemcen': 0.04,
    'Ouargla': 0.02,
    'Bouira': 0.03,
    'Tizi Ouzou': 0.06,
    'Médéa': 0.03
  },

  // Rental yield by property type and wilaya
  rentalYields: {
    'APARTMENT': {
      'Algiers': 0.05,
      'Oran': 0.06,
      'Constantine': 0.07,
      default: 0.06
    },
    'VILLA': {
      'Algiers': 0.04,
      'Oran': 0.05,
      'Constantine': 0.06,
      default: 0.05
    },
    'OFFICE': {
      'Algiers': 0.08,
      'Oran': 0.07,
      'Constantine': 0.06,
      default: 0.07
    },
    'SHOP': {
      'Algiers': 0.10,
      'Oran': 0.09,
      'Constantine': 0.08,
      default: 0.09
    }
  }
};

// Location intelligence scoring factors
export const LOCATION_FACTORS = {
  schools: {
    'Algiers': 0.9,
    'Oran': 0.8,
    'Constantine': 0.75,
    'Annaba': 0.7,
    'Blida': 0.8,
    default: 0.6
  },
  healthcare: {
    'Algiers': 0.95,
    'Oran': 0.85,
    'Constantine': 0.8,
    'Annaba': 0.75,
    'Blida': 0.8,
    default: 0.6
  },
  transport: {
    'Algiers': 0.9,
    'Oran': 0.7,
    'Constantine': 0.6,
    'Annaba': 0.6,
    'Blida': 0.8,
    default: 0.5
  },
  amenities: {
    'Algiers': 0.95,
    'Oran': 0.8,
    'Constantine': 0.75,
    'Annaba': 0.7,
    'Blida': 0.8,
    default: 0.6
  },
  safety: {
    'Algiers': 0.75,
    'Oran': 0.8,
    'Constantine': 0.85,
    'Annaba': 0.8,
    'Blida': 0.85,
    default: 0.8
  }
};

export interface MarketAnalysis {
  priceAnalysis: {
    currentPricePerSqm: number;
    marketAveragePricePerSqm: number;
    pricePositioning: 'Below Market' | 'Market Rate' | 'Premium' | 'Luxury';
    priceDeviation: number; // % deviation from market average
    competitiveAdvantage: string;
  };
  
  investmentAnalysis: {
    expectedROI: number;
    rentalYield: number;
    appreciationForecast: {
      oneYear: number;
      threeYear: number;
      fiveYear: number;
    };
    paybackPeriod: number; // years
    totalCostOfOwnership: number;
    investmentGrade: 'A+' | 'A' | 'B+' | 'B' | 'C+' | 'C' | 'D';
  };
  
  locationIntelligence: {
    overallScore: number;
    factors: {
      schools: { score: number; description: string };
      healthcare: { score: number; description: string };
      transport: { score: number; description: string };
      amenities: { score: number; description: string };
      safety: { score: number; description: string };
    };
    neighborhoodRanking: 'Top 10%' | 'Top 25%' | 'Top 50%' | 'Average' | 'Below Average';
  };
  
  marketTrends: {
    priceHistory: Array<{ period: string; averagePrice: number; change: number }>;
    marketVolume: number;
    daysOnMarket: number;
    supplyDemandRatio: number;
    marketCondition: 'Seller\'s Market' | 'Balanced Market' | 'Buyer\'s Market';
  };
  
  comparableSales: Array<{
    propertyType: string;
    size: number;
    price: number;
    pricePerSqm: number;
    location: string;
    daysAgo: number;
    similarity: number;
  }>;
  
  professionalInsights: {
    marketPosition: string;
    negotiationLeverage: 'Strong Seller' | 'Balanced' | 'Strong Buyer';
    recommendedStrategy: string;
    riskFactors: string[];
    opportunities: string[];
    keySellingPoints: string[];
  };
}

/**
 * Generate comprehensive market analysis for a property
 */
export async function generateMarketAnalysis(propertyId: string): Promise<MarketAnalysis> {
  const property = await prisma.property.findUnique({
    where: { id: propertyId },
    include: {
      sales: {
        take: 5,
        orderBy: { saleDate: 'desc' }
      }
    }
  });

  if (!property) {
    throw new Error('Property not found');
  }

  // Price Analysis
  const priceAnalysis = await analyzePricing(property);
  
  // Investment Analysis
  const investmentAnalysis = await analyzeInvestment(property);
  
  // Location Intelligence
  const locationIntelligence = await analyzeLocation(property);
  
  // Market Trends
  const marketTrends = await analyzeMarketTrends(property);
  
  // Comparable Sales
  const comparableSales = await findComparableSales(property);
  
  // Professional Insights
  const professionalInsights = generateProfessionalInsights(property, {
    priceAnalysis,
    investmentAnalysis,
    locationIntelligence,
    marketTrends
  });

  return {
    priceAnalysis,
    investmentAnalysis,
    locationIntelligence,
    marketTrends,
    comparableSales,
    professionalInsights
  };
}

/**
 * Analyze property pricing against market
 */
async function analyzePricing(property: any) {
  const currentPricePerSqm = property.price / property.area;
  const marketAverage = ALGERIA_MARKET_DATA.avgPricePerSqm[property.wilaya as keyof typeof ALGERIA_MARKET_DATA.avgPricePerSqm] || 70000;
  const priceDeviation = ((currentPricePerSqm - marketAverage) / marketAverage) * 100;
  
  let pricePositioning: 'Below Market' | 'Market Rate' | 'Premium' | 'Luxury';
  let competitiveAdvantage: string;
  
  if (priceDeviation < -15) {
    pricePositioning = 'Below Market';
    competitiveAdvantage = 'Excellent value opportunity - priced significantly below market average';
  } else if (priceDeviation < 5) {
    pricePositioning = 'Market Rate';
    competitiveAdvantage = 'Competitively priced at market standards';
  } else if (priceDeviation < 25) {
    pricePositioning = 'Premium';
    competitiveAdvantage = 'Premium positioning with superior features or location';
  } else {
    pricePositioning = 'Luxury';
    competitiveAdvantage = 'Luxury segment with exclusive features and prime location';
  }

  return {
    currentPricePerSqm,
    marketAveragePricePerSqm: marketAverage,
    pricePositioning,
    priceDeviation,
    competitiveAdvantage
  };
}

/**
 * Analyze investment potential
 */
async function analyzeInvestment(property: any) {
  const propertyType = property.propertyType as keyof typeof ALGERIA_MARKET_DATA.rentalYields;
  const wilaya = property.wilaya;
  
  // Get rental yield
  const rentalYield = ALGERIA_MARKET_DATA.rentalYields[propertyType]?.[wilaya as keyof typeof ALGERIA_MARKET_DATA.rentalYields[typeof propertyType]] 
    || ALGERIA_MARKET_DATA.rentalYields[propertyType]?.default 
    || 0.06;
  
  // Get growth rate
  const growthRate = ALGERIA_MARKET_DATA.growthRates[wilaya as keyof typeof ALGERIA_MARKET_DATA.growthRates] || 0.03;
  
  // Calculate projections
  const appreciationForecast = {
    oneYear: property.price * (1 + growthRate),
    threeYear: property.price * Math.pow(1 + growthRate, 3),
    fiveYear: property.price * Math.pow(1 + growthRate, 5)
  };
  
  const expectedROI = rentalYield + growthRate;
  const paybackPeriod = 1 / rentalYield;
  
  // Total cost including fees (using quote calculation logic)
  const totalCostOfOwnership = property.price * 1.27; // Base + 5% commission + 2% legal + 19% tax + admin fees
  
  // Investment grade
  let investmentGrade: 'A+' | 'A' | 'B+' | 'B' | 'C+' | 'C' | 'D';
  if (expectedROI >= 0.12) investmentGrade = 'A+';
  else if (expectedROI >= 0.10) investmentGrade = 'A';
  else if (expectedROI >= 0.08) investmentGrade = 'B+';
  else if (expectedROI >= 0.06) investmentGrade = 'B';
  else if (expectedROI >= 0.04) investmentGrade = 'C+';
  else if (expectedROI >= 0.02) investmentGrade = 'C';
  else investmentGrade = 'D';

  return {
    expectedROI,
    rentalYield,
    appreciationForecast,
    paybackPeriod,
    totalCostOfOwnership,
    investmentGrade
  };
}

/**
 * Analyze location intelligence
 */
async function analyzeLocation(property: any) {
  const wilaya = property.wilaya;
  
  const factors = {
    schools: {
      score: LOCATION_FACTORS.schools[wilaya as keyof typeof LOCATION_FACTORS.schools] || LOCATION_FACTORS.schools.default,
      description: getLocationDescription('schools', wilaya)
    },
    healthcare: {
      score: LOCATION_FACTORS.healthcare[wilaya as keyof typeof LOCATION_FACTORS.healthcare] || LOCATION_FACTORS.healthcare.default,
      description: getLocationDescription('healthcare', wilaya)
    },
    transport: {
      score: LOCATION_FACTORS.transport[wilaya as keyof typeof LOCATION_FACTORS.transport] || LOCATION_FACTORS.transport.default,
      description: getLocationDescription('transport', wilaya)
    },
    amenities: {
      score: LOCATION_FACTORS.amenities[wilaya as keyof typeof LOCATION_FACTORS.amenities] || LOCATION_FACTORS.amenities.default,
      description: getLocationDescription('amenities', wilaya)
    },
    safety: {
      score: LOCATION_FACTORS.safety[wilaya as keyof typeof LOCATION_FACTORS.safety] || LOCATION_FACTORS.safety.default,
      description: getLocationDescription('safety', wilaya)
    }
  };
  
  const overallScore = (factors.schools.score + factors.healthcare.score + factors.transport.score + factors.amenities.score + factors.safety.score) / 5;
  
  let neighborhoodRanking: 'Top 10%' | 'Top 25%' | 'Top 50%' | 'Average' | 'Below Average';
  if (overallScore >= 0.9) neighborhoodRanking = 'Top 10%';
  else if (overallScore >= 0.8) neighborhoodRanking = 'Top 25%';
  else if (overallScore >= 0.7) neighborhoodRanking = 'Top 50%';
  else if (overallScore >= 0.6) neighborhoodRanking = 'Average';
  else neighborhoodRanking = 'Below Average';

  return {
    overallScore,
    factors,
    neighborhoodRanking
  };
}

/**
 * Analyze market trends
 */
async function analyzeMarketTrends(property: any) {
  const wilaya = property.wilaya;
  const growthRate = ALGERIA_MARKET_DATA.growthRates[wilaya as keyof typeof ALGERIA_MARKET_DATA.growthRates] || 0.03;
  const currentAvgPrice = ALGERIA_MARKET_DATA.avgPricePerSqm[wilaya as keyof typeof ALGERIA_MARKET_DATA.avgPricePerSqm] || 70000;
  
  // Generate price history (simulated based on growth rate)
  const priceHistory = [];
  for (let i = 12; i >= 0; i--) {
    const period = new Date();
    period.setMonth(period.getMonth() - i);
    const historicalPrice = currentAvgPrice / Math.pow(1 + growthRate/12, i);
    const change = i === 12 ? 0 : ((currentAvgPrice - historicalPrice) / historicalPrice) * 100;
    
    priceHistory.push({
      period: period.toLocaleDateString('fr-FR', { year: 'numeric', month: 'short' }),
      averagePrice: Math.round(historicalPrice),
      change: Math.round(change * 100) / 100
    });
  }
  
  // Get market metrics from recent sales
  const recentSales = await prisma.sale.findMany({
    where: {
      property: {
        wilaya: property.wilaya,
        propertyType: property.propertyType
      },
      saleDate: {
        gte: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000) // Last 90 days
      }
    },
    include: { property: true }
  });

  const marketVolume = recentSales.length;
  const avgDaysOnMarket = 45; // Default for Algeria market
  const supplyDemandRatio = 1.2; // Slightly more supply than demand
  
  let marketCondition: 'Seller\'s Market' | 'Balanced Market' | 'Buyer\'s Market';
  if (supplyDemandRatio < 0.8) marketCondition = 'Seller\'s Market';
  else if (supplyDemandRatio < 1.2) marketCondition = 'Balanced Market';
  else marketCondition = 'Buyer\'s Market';

  return {
    priceHistory,
    marketVolume,
    daysOnMarket: avgDaysOnMarket,
    supplyDemandRatio,
    marketCondition
  };
}

/**
 * Find comparable sales
 */
async function findComparableSales(property: any) {
  const similarProperties = await prisma.property.findMany({
    where: {
      wilaya: property.wilaya,
      propertyType: property.propertyType,
      area: {
        gte: property.area * 0.8,
        lte: property.area * 1.2
      },
      id: { not: property.id }
    },
    include: {
      sales: {
        take: 1,
        orderBy: { saleDate: 'desc' },
        where: {
          saleDate: {
            gte: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000) // Last year
          }
        }
      }
    },
    take: 10
  });

  return similarProperties
    .filter(p => p.sales.length > 0)
    .map(p => {
      const sale = p.sales[0];
      const similarity = calculateSimilarity(property.scores, p.scores);
      const daysAgo = Math.floor((Date.now() - sale.saleDate.getTime()) / (1000 * 60 * 60 * 24));
      
      return {
        propertyType: p.propertyType,
        size: p.area,
        price: sale.salePrice,
        pricePerSqm: Math.round(sale.salePrice / p.area),
        location: `${p.city}, ${p.wilaya}`,
        daysAgo,
        similarity: Math.round(similarity * 1000) / 1000
      };
    })
    .sort((a, b) => b.similarity - a.similarity)
    .slice(0, 5);
}

/**
 * Generate professional insights
 */
function generateProfessionalInsights(property: any, analysis: any) {
  const { priceAnalysis, investmentAnalysis, locationIntelligence, marketTrends } = analysis;
  
  // Market position
  let marketPosition = '';
  if (priceAnalysis.pricePositioning === 'Below Market') {
    marketPosition = `Excellent value opportunity - property priced ${Math.abs(priceAnalysis.priceDeviation).toFixed(1)}% below market average, offering immediate equity potential.`;
  } else if (priceAnalysis.pricePositioning === 'Premium') {
    marketPosition = `Premium positioning at ${priceAnalysis.priceDeviation.toFixed(1)}% above market, justified by superior location and features.`;
  } else {
    marketPosition = `Market-rate pricing aligns with current ${property.wilaya} standards for ${property.propertyType.toLowerCase()} properties.`;
  }
  
  // Negotiation leverage
  let negotiationLeverage: 'Strong Seller' | 'Balanced' | 'Strong Buyer';
  if (marketTrends.marketCondition === 'Seller\'s Market' && priceAnalysis.pricePositioning === 'Below Market') {
    negotiationLeverage = 'Strong Seller';
  } else if (marketTrends.marketCondition === 'Buyer\'s Market' && priceAnalysis.pricePositioning === 'Premium') {
    negotiationLeverage = 'Strong Buyer';
  } else {
    negotiationLeverage = 'Balanced';
  }
  
  // Recommended strategy
  let recommendedStrategy = '';
  if (investmentAnalysis.investmentGrade === 'A+' || investmentAnalysis.investmentGrade === 'A') {
    recommendedStrategy = `Strong buy recommendation - Grade ${investmentAnalysis.investmentGrade} investment with ${(investmentAnalysis.expectedROI * 100).toFixed(1)}% expected ROI. Fast decision recommended.`;
  } else if (investmentAnalysis.investmentGrade === 'B+' || investmentAnalysis.investmentGrade === 'B') {
    recommendedStrategy = `Good investment opportunity with moderate returns. Consider negotiating price or terms to improve ROI.`;
  } else {
    recommendedStrategy = `Proceed with caution - consider property primarily for personal use rather than investment. Negotiate strongly on price.`;
  }
  
  // Risk factors
  const riskFactors = [];
  if (priceAnalysis.priceDeviation > 20) riskFactors.push('Premium pricing may limit resale liquidity');
  if (investmentAnalysis.rentalYield < 0.04) riskFactors.push('Low rental yield compared to market alternatives');
  if (locationIntelligence.overallScore < 0.6) riskFactors.push('Below-average location factors may impact appreciation');
  if (marketTrends.supplyDemandRatio > 1.5) riskFactors.push('High supply in market may pressure prices downward');
  
  // Opportunities
  const opportunities = [];
  if (priceAnalysis.priceDeviation < -10) opportunities.push('Immediate equity gain potential from below-market pricing');
  if (investmentAnalysis.expectedROI > 0.10) opportunities.push('High ROI potential for rental investment');
  if (locationIntelligence.neighborhoodRanking === 'Top 10%' || locationIntelligence.neighborhoodRanking === 'Top 25%') {
    opportunities.push('Prime location with strong appreciation potential');
  }
  if (property.condition === 'NEW' || property.condition === 'EXCELLENT') {
    opportunities.push('Excellent condition minimizes immediate maintenance costs');
  }
  
  // Key selling points
  const keySellingPoints = [];
  if (property.hasParking) keySellingPoints.push('Secured parking in high-demand area');
  if (property.hasGarden) keySellingPoints.push('Private garden space - rare for urban properties');
  if (property.hasSwimmingPool) keySellingPoints.push('Swimming pool adds premium value');
  if (locationIntelligence.factors.schools.score > 0.8) keySellingPoints.push('Excellent school district access');
  if (locationIntelligence.factors.transport.score > 0.8) keySellingPoints.push('Superior transportation connectivity');

  return {
    marketPosition,
    negotiationLeverage,
    recommendedStrategy,
    riskFactors: riskFactors.length > 0 ? riskFactors : ['Standard market risks apply'],
    opportunities: opportunities.length > 0 ? opportunities : ['Standard market opportunities'],
    keySellingPoints: keySellingPoints.length > 0 ? keySellingPoints : ['Standard property features']
  };
}

/**
 * Get location factor descriptions
 */
function getLocationDescription(factor: string, wilaya: string): string {
  const descriptions = {
    schools: {
      high: 'Excellent educational institutions including universities and international schools',
      medium: 'Good selection of public and private schools',
      low: 'Basic educational facilities available'
    },
    healthcare: {
      high: 'Major hospitals and specialized medical centers nearby',
      medium: 'Regional healthcare facilities and clinics',
      low: 'Basic healthcare services available'
    },
    transport: {
      high: 'Metro, bus networks, and highway access - excellent connectivity',
      medium: 'Good public transport and road connections',
      low: 'Limited public transport - car dependency'
    },
    amenities: {
      high: 'Shopping centers, restaurants, entertainment, and cultural facilities',
      medium: 'Good selection of local amenities and services',
      low: 'Basic amenities and services'
    },
    safety: {
      high: 'Very safe area with low crime rates and good security',
      medium: 'Generally safe with standard security measures',
      low: 'Average safety - normal urban precautions advised'
    }
  };

  const score = LOCATION_FACTORS[factor as keyof typeof LOCATION_FACTORS][wilaya as keyof typeof LOCATION_FACTORS[keyof typeof LOCATION_FACTORS]] 
    || LOCATION_FACTORS[factor as keyof typeof LOCATION_FACTORS].default;

  if (score >= 0.8) return descriptions[factor as keyof typeof descriptions].high;
  else if (score >= 0.6) return descriptions[factor as keyof typeof descriptions].medium;
  else return descriptions[factor as keyof typeof descriptions].low;
}

/**
 * Generate professional comparison between two properties
 */
export async function generateProfessionalComparison(property1Id: string, property2Id: string, contactId?: string) {
  const [analysis1, analysis2] = await Promise.all([
    generateMarketAnalysis(property1Id),
    generateMarketAnalysis(property2Id)
  ]);

  const property1 = await prisma.property.findUnique({ where: { id: property1Id } });
  const property2 = await prisma.property.findUnique({ where: { id: property2Id } });

  if (!property1 || !property2) {
    throw new Error('Properties not found');
  }

  // Professional comparison analysis
  const comparison = {
    executiveSummary: generateExecutiveSummary(property1, property2, analysis1, analysis2),
    financialAnalysis: compareFinancials(analysis1, analysis2),
    investmentAnalysis: compareInvestments(analysis1, analysis2),
    locationAnalysis: compareLocations(analysis1, analysis2),
    marketAnalysis: compareMarketPosition(analysis1, analysis2),
    riskAssessment: compareRisks(analysis1, analysis2),
    professionalRecommendation: generateProfessionalRecommendation(property1, property2, analysis1, analysis2, contactId)
  };

  return {
    property1: { ...property1, analysis: analysis1 },
    property2: { ...property2, analysis: analysis2 },
    comparison
  };
}

// Helper functions for professional comparison
function generateExecutiveSummary(prop1: any, prop2: any, analysis1: any, analysis2: any) {
  const better1 = [];
  const better2 = [];

  if (analysis1.investmentAnalysis.expectedROI > analysis2.investmentAnalysis.expectedROI) {
    better1.push('higher ROI potential');
  } else {
    better2.push('higher ROI potential');
  }

  if (analysis1.priceAnalysis.priceDeviation < analysis2.priceAnalysis.priceDeviation) {
    better1.push('better value pricing');
  } else {
    better2.push('better value pricing');
  }

  if (analysis1.locationIntelligence.overallScore > analysis2.locationIntelligence.overallScore) {
    better1.push('superior location score');
  } else {
    better2.push('superior location score');
  }

  return {
    property1Advantages: better1,
    property2Advantages: better2,
    summary: `Property comparison reveals distinct advantages for each option based on investment potential, location factors, and market positioning.`
  };
}

function compareFinancials(analysis1: any, analysis2: any) {
  return {
    pricePerSqm: {
      property1: analysis1.priceAnalysis.currentPricePerSqm,
      property2: analysis2.priceAnalysis.currentPricePerSqm,
      advantage: analysis1.priceAnalysis.currentPricePerSqm < analysis2.priceAnalysis.currentPricePerSqm ? 'property1' : 'property2',
      difference: Math.abs(analysis1.priceAnalysis.currentPricePerSqm - analysis2.priceAnalysis.currentPricePerSqm)
    },
    totalCost: {
      property1: analysis1.investmentAnalysis.totalCostOfOwnership,
      property2: analysis2.investmentAnalysis.totalCostOfOwnership,
      advantage: analysis1.investmentAnalysis.totalCostOfOwnership < analysis2.investmentAnalysis.totalCostOfOwnership ? 'property1' : 'property2'
    },
    marketPositioning: {
      property1: analysis1.priceAnalysis.pricePositioning,
      property2: analysis2.priceAnalysis.pricePositioning
    }
  };
}

function compareInvestments(analysis1: any, analysis2: any) {
  return {
    expectedROI: {
      property1: analysis1.investmentAnalysis.expectedROI,
      property2: analysis2.investmentAnalysis.expectedROI,
      advantage: analysis1.investmentAnalysis.expectedROI > analysis2.investmentAnalysis.expectedROI ? 'property1' : 'property2'
    },
    rentalYield: {
      property1: analysis1.investmentAnalysis.rentalYield,
      property2: analysis2.investmentAnalysis.rentalYield,
      advantage: analysis1.investmentAnalysis.rentalYield > analysis2.investmentAnalysis.rentalYield ? 'property1' : 'property2'
    },
    investmentGrade: {
      property1: analysis1.investmentAnalysis.investmentGrade,
      property2: analysis2.investmentAnalysis.investmentGrade
    },
    appreciation5Year: {
      property1: analysis1.investmentAnalysis.appreciationForecast.fiveYear,
      property2: analysis2.investmentAnalysis.appreciationForecast.fiveYear,
      advantage: analysis1.investmentAnalysis.appreciationForecast.fiveYear > analysis2.investmentAnalysis.appreciationForecast.fiveYear ? 'property1' : 'property2'
    }
  };
}

function compareLocations(analysis1: any, analysis2: any) {
  return {
    overallScore: {
      property1: analysis1.locationIntelligence.overallScore,
      property2: analysis2.locationIntelligence.overallScore,
      advantage: analysis1.locationIntelligence.overallScore > analysis2.locationIntelligence.overallScore ? 'property1' : 'property2'
    },
    neighborhoodRanking: {
      property1: analysis1.locationIntelligence.neighborhoodRanking,
      property2: analysis2.locationIntelligence.neighborhoodRanking
    },
    factorComparison: {
      schools: {
        property1: analysis1.locationIntelligence.factors.schools.score,
        property2: analysis2.locationIntelligence.factors.schools.score,
        advantage: analysis1.locationIntelligence.factors.schools.score > analysis2.locationIntelligence.factors.schools.score ? 'property1' : 'property2'
      },
      transport: {
        property1: analysis1.locationIntelligence.factors.transport.score,
        property2: analysis2.locationIntelligence.factors.transport.score,
        advantage: analysis1.locationIntelligence.factors.transport.score > analysis2.locationIntelligence.factors.transport.score ? 'property1' : 'property2'
      },
      amenities: {
        property1: analysis1.locationIntelligence.factors.amenities.score,
        property2: analysis2.locationIntelligence.factors.amenities.score,
        advantage: analysis1.locationIntelligence.factors.amenities.score > analysis2.locationIntelligence.factors.amenities.score ? 'property1' : 'property2'
      }
    }
  };
}

function compareMarketPosition(analysis1: any, analysis2: any) {
  return {
    marketCondition: {
      property1: analysis1.marketTrends.marketCondition,
      property2: analysis2.marketTrends.marketCondition
    },
    negotiationLeverage: {
      property1: analysis1.professionalInsights.negotiationLeverage,
      property2: analysis2.professionalInsights.negotiationLeverage
    },
    marketVolume: {
      property1: analysis1.marketTrends.marketVolume,
      property2: analysis2.marketTrends.marketVolume,
      advantage: analysis1.marketTrends.marketVolume > analysis2.marketTrends.marketVolume ? 'property1' : 'property2'
    }
  };
}

function compareRisks(analysis1: any, analysis2: any) {
  return {
    property1Risks: analysis1.professionalInsights.riskFactors,
    property2Risks: analysis2.professionalInsights.riskFactors,
    riskAssessment: {
      property1: analysis1.professionalInsights.riskFactors.length,
      property2: analysis2.professionalInsights.riskFactors.length,
      lowerRisk: analysis1.professionalInsights.riskFactors.length < analysis2.professionalInsights.riskFactors.length ? 'property1' : 'property2'
    }
  };
}

function generateProfessionalRecommendation(prop1: any, prop2: any, analysis1: any, analysis2: any, contactId?: string) {
  // Score each property on multiple factors
  let score1 = 0;
  let score2 = 0;

  // Investment potential (40% weight)
  if (analysis1.investmentAnalysis.expectedROI > analysis2.investmentAnalysis.expectedROI) score1 += 4;
  else score2 += 4;

  // Value for money (30% weight)
  if (analysis1.priceAnalysis.priceDeviation < analysis2.priceAnalysis.priceDeviation) score1 += 3;
  else score2 += 3;

  // Location quality (20% weight)
  if (analysis1.locationIntelligence.overallScore > analysis2.locationIntelligence.overallScore) score1 += 2;
  else score2 += 2;

  // Risk assessment (10% weight)
  if (analysis1.professionalInsights.riskFactors.length < analysis2.professionalInsights.riskFactors.length) score1 += 1;
  else score2 += 1;

  const recommendedProperty = score1 > score2 ? 'property1' : 'property2';
  const winningAnalysis = score1 > score2 ? analysis1 : analysis2;
  const winningProperty = score1 > score2 ? prop1 : prop2;

  return {
    recommendedProperty,
    confidenceLevel: Math.abs(score1 - score2) > 4 ? 'High' : Math.abs(score1 - score2) > 2 ? 'Medium' : 'Low',
    reasoning: `Based on comprehensive analysis, ${winningProperty.title} is recommended due to ${winningAnalysis.investmentAnalysis.investmentGrade} investment grade and ${winningAnalysis.professionalInsights.marketPosition}`,
    actionPlan: [
      'Conduct physical inspection with qualified surveyor',
      'Verify all legal documentation and property rights',
      'Negotiate based on market analysis findings',
      'Consider financing options and total cost implications',
      'Plan due diligence timeline and closing procedures'
    ],
    nextSteps: `Priority: ${winningAnalysis.professionalInsights.recommendedStrategy}`
  };
} 