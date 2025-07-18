/**
 * Quote Generation Service for Algeria Real Estate
 * 
 * Generates comprehensive property quotes and invoices with:
 * - Pricing calculations and breakdowns
 * - Agent commissions and fees  
 * - Legal and administrative costs
 * - Market-specific adjustments for Algeria
 * - Multi-language support (Arabic, French, English)
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface QuoteConfig {
  agentCommissionRate: number; // Percentage (e.g., 0.05 for 5%)
  legalFeesRate: number; // Percentage for legal fees
  administrativeFees: number; // Fixed amount in DZD
  taxRate: number; // VAT/Tax rate
  validityDays: number; // Quote validity period
  currency: string; // Currency code (DZD)
  language: 'ar' | 'fr' | 'en'; // Quote language
}

export interface QuoteItem {
  description: string;
  amount: number;
  type: 'base' | 'commission' | 'fee' | 'tax' | 'discount';
  percentage?: number;
}

export interface PropertyQuote {
  id: string;
  quoteNumber: string;
  property: {
    id: string;
    title: string;
    price: number;
    area: number;
    rooms: number;
    wilaya: string;
    city: string;
    propertyType: string;
    transactionType: string;
  };
  contact?: {
    id: string;
    name: string;
    email: string;
    phone?: string;
    type: string;
  };
  agent?: {
    id: string;
    name: string;
    email: string;
    phone?: string;
  };
  pricing: {
    basePrice: number;
    agentCommission: number;
    legalFees: number;
    administrativeFees: number;
    taxes: number;
    totalAmount: number;
    breakdown: QuoteItem[];
  };
  terms: {
    validUntil: Date;
    paymentTerms: string;
    conditions: string[];
  };
  createdAt: Date;
  updatedAt: Date;
  status: 'draft' | 'sent' | 'accepted' | 'rejected' | 'expired';
  language: string;
  currency: string;
}

/**
 * Get default quote configuration
 */
export async function getQuoteConfig(): Promise<QuoteConfig> {
  const settings = await prisma.setting.findMany({
    where: {
      key: {
        in: [
          'agent_commission_rate',
          'legal_fees_rate',
          'administrative_fees',
          'tax_rate',
          'quote_validity_days',
          'default_currency',
          'default_language'
        ]
      }
    }
  });

  const config: QuoteConfig = {
    agentCommissionRate: 0.05, // 5% default
    legalFeesRate: 0.02, // 2% default
    administrativeFees: 50000, // 50,000 DZD default
    taxRate: 0.19, // 19% VAT default
    validityDays: 30, // 30 days default
    currency: 'DZD',
    language: 'fr'
  };

  // Override with database settings
  settings.forEach(setting => {
    switch (setting.key) {
      case 'agent_commission_rate':
        config.agentCommissionRate = parseFloat(setting.value);
        break;
      case 'legal_fees_rate':
        config.legalFeesRate = parseFloat(setting.value);
        break;
      case 'administrative_fees':
        config.administrativeFees = parseFloat(setting.value);
        break;
      case 'tax_rate':
        config.taxRate = parseFloat(setting.value);
        break;
      case 'quote_validity_days':
        config.validityDays = parseInt(setting.value);
        break;
      case 'default_currency':
        config.currency = setting.value;
        break;
      case 'default_language':
        config.language = setting.value as 'ar' | 'fr' | 'en';
        break;
    }
  });

  return config;
}

/**
 * Generate property quote
 */
export async function generatePropertyQuote(
  propertyId: string,
  contactId?: string,
  agentId?: string,
  customConfig?: Partial<QuoteConfig>
): Promise<PropertyQuote> {
  // Get property details
  const property = await prisma.property.findUnique({
    where: { id: propertyId }
  });

  if (!property) {
    throw new Error('Property not found');
  }

  // Get contact details if provided
  let contact = null;
  if (contactId) {
    contact = await prisma.contact.findUnique({
      where: { id: contactId }
    });
  }

  // Get agent details if provided (for future implementation)
  let agent: { id: string; name: string; email: string; phone?: string } | undefined = undefined;
  if (agentId) {
    // For now, we'll use a placeholder since agent table might not exist
    agent = {
      id: agentId,
      name: 'Agent Name',
      email: 'agent@example.com',
      phone: '+213-XXX-XXX-XXX'
    };
  }

  // Get quote configuration
  const config = { ...await getQuoteConfig(), ...customConfig };

  // Calculate pricing breakdown
  const basePrice = property.price;
  const agentCommission = basePrice * config.agentCommissionRate;
  const legalFees = basePrice * config.legalFeesRate;
  const administrativeFees = config.administrativeFees;
  
  // Calculate subtotal before taxes
  const subtotal = basePrice + agentCommission + legalFees + administrativeFees;
  const taxes = subtotal * config.taxRate;
  const totalAmount = subtotal + taxes;

  // Create detailed breakdown
  const breakdown: QuoteItem[] = [
    {
      description: getLocalizedText('base_price', config.language),
      amount: basePrice,
      type: 'base'
    },
    {
      description: getLocalizedText('agent_commission', config.language),
      amount: agentCommission,
      type: 'commission',
      percentage: config.agentCommissionRate * 100
    },
    {
      description: getLocalizedText('legal_fees', config.language),
      amount: legalFees,
      type: 'fee',
      percentage: config.legalFeesRate * 100
    },
    {
      description: getLocalizedText('administrative_fees', config.language),
      amount: administrativeFees,
      type: 'fee'
    },
    {
      description: getLocalizedText('taxes', config.language),
      amount: taxes,
      type: 'tax',
      percentage: config.taxRate * 100
    }
  ];

  // Generate unique quote number
  const quoteNumber = await generateQuoteNumber();

  // Calculate validity date
  const validUntil = new Date();
  validUntil.setDate(validUntil.getDate() + config.validityDays);

  // Create quote object
  const quote: PropertyQuote = {
    id: '', // Will be set when saved to database
    quoteNumber,
    property: {
      id: property.id,
      title: property.title,
      price: property.price,
      area: property.area,
      rooms: property.rooms,
      wilaya: property.wilaya,
      city: property.city,
      propertyType: property.propertyType,
      transactionType: property.transactionType
    },
    contact: contact ? {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone: contact.phone || undefined,
      type: contact.type
    } : undefined,
    agent,
    pricing: {
      basePrice,
      agentCommission,
      legalFees,
      administrativeFees,
      taxes,
      totalAmount,
      breakdown
    },
    terms: {
      validUntil,
      paymentTerms: getLocalizedText('payment_terms', config.language),
      conditions: getLocalizedTermsAndConditions(config.language)
    },
    createdAt: new Date(),
    updatedAt: new Date(),
    status: 'draft',
    language: config.language,
    currency: config.currency
  };

  return quote;
}

/**
 * Calculate quote total with discounts or adjustments
 */
export function calculateQuoteTotal(
  basePrice: number,
  adjustments: { type: 'discount' | 'surcharge'; amount: number; description: string }[] = [],
  config: QuoteConfig
): { total: number; breakdown: QuoteItem[] } {
  const breakdown: QuoteItem[] = [
    {
      description: 'Base Price',
      amount: basePrice,
      type: 'base'
    }
  ];

  let currentTotal = basePrice;

  // Apply adjustments
  adjustments.forEach(adjustment => {
    breakdown.push({
      description: adjustment.description,
      amount: adjustment.type === 'discount' ? -adjustment.amount : adjustment.amount,
      type: adjustment.type === 'discount' ? 'discount' : 'fee'
    });
    
    currentTotal += adjustment.type === 'discount' ? -adjustment.amount : adjustment.amount;
  });

  // Add commission
  const commission = currentTotal * config.agentCommissionRate;
  breakdown.push({
    description: 'Agent Commission',
    amount: commission,
    type: 'commission',
    percentage: config.agentCommissionRate * 100
  });
  currentTotal += commission;

  // Add legal fees
  const legalFees = currentTotal * config.legalFeesRate;
  breakdown.push({
    description: 'Legal Fees',
    amount: legalFees,
    type: 'fee',
    percentage: config.legalFeesRate * 100
  });
  currentTotal += legalFees;

  // Add administrative fees
  breakdown.push({
    description: 'Administrative Fees',
    amount: config.administrativeFees,
    type: 'fee'
  });
  currentTotal += config.administrativeFees;

  // Add taxes
  const taxes = currentTotal * config.taxRate;
  breakdown.push({
    description: 'Taxes (VAT)',
    amount: taxes,
    type: 'tax',
    percentage: config.taxRate * 100
  });
  currentTotal += taxes;

  return {
    total: Math.round(currentTotal),
    breakdown
  };
}

/**
 * Generate unique quote number
 */
async function generateQuoteNumber(): Promise<string> {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  
  // Get count of quotes created today for sequential numbering
  const startOfDay = new Date(year, now.getMonth(), now.getDate());
  const endOfDay = new Date(year, now.getMonth(), now.getDate() + 1);
  
  // For now, use timestamp-based numbering since we don't have quotes table yet
  const timestamp = now.getTime().toString().slice(-6);
  
  return `QUO-${year}${month}${day}-${timestamp}`;
}

/**
 * Get localized text for quote items
 */
function getLocalizedText(key: string, language: 'ar' | 'fr' | 'en'): string {
  const translations = {
    base_price: {
      ar: 'السعر الأساسي',
      fr: 'Prix de base',
      en: 'Base Price'
    },
    agent_commission: {
      ar: 'عمولة الوكيل',
      fr: 'Commission agent',
      en: 'Agent Commission'
    },
    legal_fees: {
      ar: 'الرسوم القانونية',
      fr: 'Frais juridiques',
      en: 'Legal Fees'
    },
    administrative_fees: {
      ar: 'الرسوم الإدارية',
      fr: 'Frais administratifs',
      en: 'Administrative Fees'
    },
    taxes: {
      ar: 'الضرائب',
      fr: 'Taxes (TVA)',
      en: 'Taxes (VAT)'
    },
    payment_terms: {
      ar: 'شروط الدفع: 30 يوم من تاريخ القبول',
      fr: 'Conditions de paiement: 30 jours à partir de l\'acceptation',
      en: 'Payment Terms: 30 days from acceptance'
    }
  };

  return translations[key as keyof typeof translations]?.[language] || translations[key as keyof typeof translations]?.en || key;
}

/**
 * Get localized terms and conditions
 */
function getLocalizedTermsAndConditions(language: 'ar' | 'fr' | 'en'): string[] {
  const terms = {
    ar: [
      'هذا العرض صالح للمدة المحددة أعلاه',
      'جميع الأسعار بالدينار الجزائري',
      'يخضع البيع للقانون الجزائري',
      'المفاوضة ممكنة حسب ظروف السوق'
    ],
    fr: [
      'Cette offre est valable pour la période spécifiée ci-dessus',
      'Tous les prix sont en dinars algériens',
      'La vente est soumise au droit algérien',
      'Négociation possible selon les conditions du marché'
    ],
    en: [
      'This offer is valid for the period specified above',
      'All prices are in Algerian Dinars',
      'Sale is subject to Algerian law',
      'Negotiation possible based on market conditions'
    ]
  };

  return terms[language] || terms.en;
}

/**
 * Format currency for display
 */
export function formatCurrency(amount: number, currency: string = 'DZD', language: 'ar' | 'fr' | 'en' = 'fr'): string {
  const formatter = new Intl.NumberFormat(
    language === 'ar' ? 'ar-DZ' : language === 'fr' ? 'fr-DZ' : 'en-US',
    {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }
  );

  // For DZD, we'll format manually as Intl may not support it properly
  if (currency === 'DZD') {
    const formatted = new Intl.NumberFormat(
      language === 'ar' ? 'ar-DZ' : language === 'fr' ? 'fr-FR' : 'en-US'
    ).format(amount);
    
    return language === 'ar' ? `${formatted} د.ج` : `${formatted} DZD`;
  }

  return formatter.format(amount);
}

/**
 * Validate quote data
 */
export function validateQuoteData(quote: Partial<PropertyQuote>): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!quote.property?.id) {
    errors.push('Property ID is required');
  }

  if (!quote.pricing?.basePrice || quote.pricing.basePrice <= 0) {
    errors.push('Valid base price is required');
  }

  if (!quote.quoteNumber) {
    errors.push('Quote number is required');
  }

  if (!quote.terms?.validUntil || quote.terms.validUntil <= new Date()) {
    errors.push('Valid expiration date is required');
  }

  return {
    valid: errors.length === 0,
    errors
  };
} 