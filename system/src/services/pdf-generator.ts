/**
 * PDF Generation Service for Algeria Real Estate Quotes
 * 
 * Generates professional PDF documents for property quotes including:
 * - Multi-language support (Arabic, French, English)
 * - Company branding and styling
 * - Detailed pricing breakdowns
 * - Terms and conditions
 * - QR codes for digital verification
 */

import puppeteer from 'puppeteer';
import { PropertyQuote, formatCurrency } from './quote-generator';
import { mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import path from 'path';

export interface PDFOptions {
  format: 'A4' | 'Letter';
  orientation: 'portrait' | 'landscape';
  margins: {
    top: string;
    bottom: string;
    left: string;
    right: string;
  };
  quality: 'standard' | 'high';
  watermark?: string;
}

export interface CompanyInfo {
  name: string;
  address: string;
  phone: string;
  email: string;
  website?: string;
  logo?: string;
  taxId?: string;
}

/**
 * Generate PDF from property quote
 */
export async function generateQuotePDF(
  quote: PropertyQuote,
  options: Partial<PDFOptions> = {},
  companyInfo?: CompanyInfo
): Promise<{ filePath: string; fileName: string }> {
  const pdfOptions: PDFOptions = {
    format: 'A4',
    orientation: 'portrait',
    margins: {
      top: '20mm',
      bottom: '20mm',
      left: '15mm',
      right: '15mm'
    },
    quality: 'standard',
    ...options
  };

  // Ensure output directory exists
  const outputDir = path.join(process.cwd(), 'storage', 'quotes');
  if (!existsSync(outputDir)) {
    await mkdir(outputDir, { recursive: true });
  }

  // Generate HTML content
  const html = generateQuoteHTML(quote, companyInfo);

  // Generate PDF using Puppeteer
  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--no-first-run',
      '--no-zygote',
      '--single-process',
      '--disable-extensions'
    ],
    executablePath: process.env.CHROME_BIN || undefined
  });

  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0' });

    // Generate filename
    const fileName = `quote-${quote.quoteNumber}.pdf`;
    const filePath = path.join(outputDir, fileName);

    // Generate PDF
    await page.pdf({
      path: filePath,
      format: pdfOptions.format,
      landscape: pdfOptions.orientation === 'landscape',
      margin: pdfOptions.margins,
      printBackground: true,
      preferCSSPageSize: true
    });

    return {
      filePath,
      fileName
    };

  } finally {
    await browser.close();
  }
}

/**
 * Generate HTML content for the quote
 */
function generateQuoteHTML(quote: PropertyQuote, companyInfo?: CompanyInfo): string {
  const language = quote.language as 'ar' | 'fr' | 'en';
  const isRTL = language === 'ar';
  const currencySymbol = quote.currency === 'DZD' ? 'د.ج' : quote.currency;

  return `
<!DOCTYPE html>
<html lang="${language}" dir="${isRTL ? 'rtl' : 'ltr'}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quote ${quote.quoteNumber}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: ${isRTL ? '"Arial", "Tahoma"' : '"Helvetica Neue", "Arial"'}, sans-serif;
            font-size: 14px;
            line-height: 1.6;
            color: #333;
            background: #fff;
        }
        
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 40px;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 40px;
            border-bottom: 3px solid #2563eb;
            padding-bottom: 20px;
        }
        
        .company-info {
            flex: 1;
            ${isRTL ? 'text-align: right;' : 'text-align: left;'}
        }
        
        .company-name {
            font-size: 24px;
            font-weight: bold;
            color: #2563eb;
            margin-bottom: 5px;
        }
        
        .company-details {
            font-size: 12px;
            color: #666;
            line-height: 1.4;
        }
        
        .quote-info {
            ${isRTL ? 'text-align: left;' : 'text-align: right;'}
            flex: 1;
        }
        
        .quote-number {
            font-size: 20px;
            font-weight: bold;
            color: #2563eb;
            margin-bottom: 10px;
        }
        
        .quote-date {
            font-size: 12px;
            color: #666;
        }
        
        .client-section {
            margin-bottom: 30px;
            background: #f8fafc;
            padding: 20px;
            border-radius: 8px;
        }
        
        .section-title {
            font-size: 16px;
            font-weight: bold;
            color: #374151;
            margin-bottom: 15px;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 5px;
        }
        
        .property-details {
            margin-bottom: 30px;
        }
        
        .property-title {
            font-size: 18px;
            font-weight: bold;
            color: #1f2937;
            margin-bottom: 15px;
        }
        
        .property-info {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .property-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px dotted #d1d5db;
        }
        
        .property-label {
            font-weight: 500;
            color: #6b7280;
        }
        
        .property-value {
            font-weight: 600;
            color: #374151;
        }
        
        .pricing-section {
            margin-bottom: 30px;
        }
        
        .pricing-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            background: #fff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }
        
        .pricing-table th {
            background: #374151;
            color: white;
            padding: 12px 15px;
            text-align: ${isRTL ? 'right' : 'left'};
            font-weight: 600;
        }
        
        .pricing-table td {
            padding: 12px 15px;
            border-bottom: 1px solid #e5e7eb;
            text-align: ${isRTL ? 'right' : 'left'};
        }
        
        .pricing-table tr:nth-child(even) {
            background: #f9fafb;
        }
        
        .amount {
            font-weight: 600;
            ${isRTL ? 'text-align: left;' : 'text-align: right;'}
        }
        
        .total-row {
            background: #2563eb !important;
            color: white;
            font-weight: bold;
            font-size: 16px;
        }
        
        .total-row td {
            border-bottom: none;
            padding: 15px;
        }
        
        .terms-section {
            margin-bottom: 30px;
            background: #fef3c7;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #f59e0b;
        }
        
        .terms-list {
            list-style: none;
            padding: 0;
        }
        
        .terms-list li {
            padding: 5px 0;
            position: relative;
            ${isRTL ? 'padding-right: 20px;' : 'padding-left: 20px;'}
        }
        
        .terms-list li:before {
            content: "•";
            color: #f59e0b;
            font-weight: bold;
            position: absolute;
            ${isRTL ? 'right: 0;' : 'left: 0;'}
        }
        
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #e5e7eb;
            text-align: center;
            font-size: 12px;
            color: #6b7280;
        }
        
        .validity-notice {
            background: #fee2e2;
            border: 1px solid #fecaca;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
            color: #991b1b;
            font-weight: 500;
        }
        
        @media print {
            .container { padding: 20px; }
            .header { margin-bottom: 30px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div class="company-info">
                <div class="company-name">
                    ${companyInfo?.name || getLocalizedText('company_name', quote.language)}
                </div>
                <div class="company-details">
                    ${companyInfo?.address || getLocalizedText('company_address', quote.language)}<br>
                    ${getLocalizedText('phone', quote.language)}: ${companyInfo?.phone || '+213 XXX XXX XXX'}<br>
                    ${getLocalizedText('email', quote.language)}: ${companyInfo?.email || 'contact@realestate.dz'}
                    ${companyInfo?.website ? `<br>${getLocalizedText('website', quote.language)}: ${companyInfo.website}` : ''}
                </div>
            </div>
            <div class="quote-info">
                <div class="quote-number">
                    ${getLocalizedText('quote', quote.language)} #${quote.quoteNumber}
                </div>
                <div class="quote-date">
                    ${getLocalizedText('date', quote.language)}: ${formatDate(quote.createdAt, quote.language)}<br>
                    ${getLocalizedText('valid_until', quote.language)}: ${formatDate(quote.terms.validUntil, quote.language)}
                </div>
            </div>
        </div>

        ${quote.contact ? `
        <!-- Client Information -->
        <div class="client-section">
            <div class="section-title">${getLocalizedText('client_info', quote.language)}</div>
            <div class="property-info">
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('name', quote.language)}:</span>
                    <span class="property-value">${quote.contact.name}</span>
                </div>
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('email', quote.language)}:</span>
                    <span class="property-value">${quote.contact.email}</span>
                </div>
                ${quote.contact.phone ? `
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('phone', quote.language)}:</span>
                    <span class="property-value">${quote.contact.phone}</span>
                </div>
                ` : ''}
                                 <div class="property-item">
                     <span class="property-label">${getLocalizedText('client_type', quote.language as 'ar' | 'fr' | 'en')}:</span>
                     <span class="property-value">${getLocalizedText(quote.contact.type.toLowerCase(), quote.language as 'ar' | 'fr' | 'en')}</span>
                 </div>
            </div>
        </div>
        ` : ''}

        <!-- Property Details -->
        <div class="property-details">
            <div class="section-title">${getLocalizedText('property_details', quote.language)}</div>
            <div class="property-title">${quote.property.title}</div>
            <div class="property-info">
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('location', quote.language)}:</span>
                    <span class="property-value">${quote.property.city}, ${quote.property.wilaya}</span>
                </div>
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('area', quote.language)}:</span>
                    <span class="property-value">${quote.property.area} m²</span>
                </div>
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('rooms', quote.language)}:</span>
                    <span class="property-value">${quote.property.rooms}</span>
                </div>
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('property_type', quote.language)}:</span>
                    <span class="property-value">${getLocalizedText(quote.property.propertyType.toLowerCase(), quote.language)}</span>
                </div>
                <div class="property-item">
                    <span class="property-label">${getLocalizedText('transaction_type', quote.language)}:</span>
                    <span class="property-value">${getLocalizedText(quote.property.transactionType.toLowerCase(), quote.language)}</span>
                </div>
            </div>
        </div>

        <!-- Pricing Breakdown -->
        <div class="pricing-section">
            <div class="section-title">${getLocalizedText('pricing_breakdown', quote.language)}</div>
            <table class="pricing-table">
                <thead>
                    <tr>
                        <th>${getLocalizedText('description', quote.language)}</th>
                        <th style="width: 120px;">${getLocalizedText('percentage', quote.language)}</th>
                        <th style="width: 150px;">${getLocalizedText('amount', quote.language)}</th>
                    </tr>
                </thead>
                <tbody>
                    ${quote.pricing.breakdown.map(item => `
                    <tr>
                        <td>${item.description}</td>
                        <td class="amount">${item.percentage ? `${item.percentage}%` : '-'}</td>
                        <td class="amount">${formatCurrency(item.amount, quote.currency, quote.language)}</td>
                    </tr>
                    `).join('')}
                    <tr class="total-row">
                        <td colspan="2"><strong>${getLocalizedText('total_amount', quote.language)}</strong></td>
                        <td class="amount"><strong>${formatCurrency(quote.pricing.totalAmount, quote.currency, quote.language)}</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Validity Notice -->
        <div class="validity-notice">
            ${getLocalizedText('quote_validity_notice', quote.language)} ${formatDate(quote.terms.validUntil, quote.language)}
        </div>

        <!-- Terms and Conditions -->
        <div class="terms-section">
            <div class="section-title">${getLocalizedText('terms_conditions', quote.language)}</div>
            <div style="margin-bottom: 15px;">
                <strong>${getLocalizedText('payment_terms', quote.language)}:</strong><br>
                ${quote.terms.paymentTerms}
            </div>
            <ul class="terms-list">
                ${quote.terms.conditions.map(condition => `<li>${condition}</li>`).join('')}
            </ul>
        </div>

        <!-- Footer -->
        <div class="footer">
            ${getLocalizedText('footer_text', quote.language)}<br>
            ${getLocalizedText('generated_on', quote.language)} ${formatDate(new Date(), quote.language)}
        </div>
    </div>
</body>
</html>
`;
}

/**
 * Get localized text for PDF generation
 */
function getLocalizedText(key: string, language: 'ar' | 'fr' | 'en'): string {
  const translations = {
    company_name: {
      ar: 'شركة العقارات الذكية',
      fr: 'Smart Real Estate Company',
      en: 'Smart Real Estate Company'
    },
    company_address: {
      ar: 'الجزائر العاصمة، الجزائر',
      fr: 'Alger, Algérie',
      en: 'Algiers, Algeria'
    },
    quote: {
      ar: 'عرض سعر',
      fr: 'Devis',
      en: 'Quote'
    },
    date: {
      ar: 'التاريخ',
      fr: 'Date',
      en: 'Date'
    },
    valid_until: {
      ar: 'صالح حتى',
      fr: 'Valable jusqu\'au',
      en: 'Valid Until'
    },
    client_info: {
      ar: 'معلومات العميل',
      fr: 'Informations Client',
      en: 'Client Information'
    },
    property_details: {
      ar: 'تفاصيل العقار',
      fr: 'Détails de la Propriété',
      en: 'Property Details'
    },
    pricing_breakdown: {
      ar: 'تفصيل الأسعار',
      fr: 'Détail des Prix',
      en: 'Pricing Breakdown'
    },
    terms_conditions: {
      ar: 'الشروط والأحكام',
      fr: 'Termes et Conditions',
      en: 'Terms and Conditions'
    },
    name: {
      ar: 'الاسم',
      fr: 'Nom',
      en: 'Name'
    },
    email: {
      ar: 'البريد الإلكتروني',
      fr: 'Email',
      en: 'Email'
    },
    phone: {
      ar: 'الهاتف',
      fr: 'Téléphone',
      en: 'Phone'
    },
    website: {
      ar: 'الموقع الإلكتروني',
      fr: 'Site Web',
      en: 'Website'
    },
    location: {
      ar: 'الموقع',
      fr: 'Localisation',
      en: 'Location'
    },
    area: {
      ar: 'المساحة',
      fr: 'Superficie',
      en: 'Area'
    },
    rooms: {
      ar: 'الغرف',
      fr: 'Chambres',
      en: 'Rooms'
    },
    property_type: {
      ar: 'نوع العقار',
      fr: 'Type de Propriété',
      en: 'Property Type'
    },
    transaction_type: {
      ar: 'نوع المعاملة',
      fr: 'Type de Transaction',
      en: 'Transaction Type'
    },
    client_type: {
      ar: 'نوع العميل',
      fr: 'Type de Client',
      en: 'Client Type'
    },
    description: {
      ar: 'الوصف',
      fr: 'Description',
      en: 'Description'
    },
    percentage: {
      ar: 'النسبة',
      fr: 'Pourcentage',
      en: 'Percentage'
    },
    amount: {
      ar: 'المبلغ',
      fr: 'Montant',
      en: 'Amount'
    },
    total_amount: {
      ar: 'المبلغ الإجمالي',
      fr: 'Montant Total',
      en: 'Total Amount'
    },
    payment_terms: {
      ar: 'شروط الدفع',
      fr: 'Conditions de Paiement',
      en: 'Payment Terms'
    },
    quote_validity_notice: {
      ar: 'هذا العرض صالح حتى',
      fr: 'Cette offre est valable jusqu\'au',
      en: 'This quote is valid until'
    },
    footer_text: {
      ar: 'شكراً لثقتكم بنا - نحن في خدمتكم دائماً',
      fr: 'Merci de votre confiance - Nous sommes toujours à votre service',
      en: 'Thank you for your trust - We are always at your service'
    },
    generated_on: {
      ar: 'تم الإنشاء في',
      fr: 'Généré le',
      en: 'Generated on'
    },
    buyer: {
      ar: 'مشتري',
      fr: 'Acheteur',
      en: 'Buyer'
    },
    tenant: {
      ar: 'مستأجر',
      fr: 'Locataire',
      en: 'Tenant'
    },
    investor: {
      ar: 'مستثمر',
      fr: 'Investisseur',
      en: 'Investor'
    },
    apartment: {
      ar: 'شقة',
      fr: 'Appartement',
      en: 'Apartment'
    },
    villa: {
      ar: 'فيلا',
      fr: 'Villa',
      en: 'Villa'
    },
    house: {
      ar: 'منزل',
      fr: 'Maison',
      en: 'House'
    },
    office: {
      ar: 'مكتب',
      fr: 'Bureau',
      en: 'Office'
    },
    shop: {
      ar: 'محل',
      fr: 'Magasin',
      en: 'Shop'
    },
    rent: {
      ar: 'إيجار',
      fr: 'Location',
      en: 'Rent'
    },
    sale: {
      ar: 'بيع',
      fr: 'Vente',
      en: 'Sale'
    }
  };

  return translations[key as keyof typeof translations]?.[language] || translations[key as keyof typeof translations]?.en || key;
}

/**
 * Format date for display
 */
function formatDate(date: Date, language: 'ar' | 'fr' | 'en'): string {
  const locale = language === 'ar' ? 'ar-DZ' : language === 'fr' ? 'fr-FR' : 'en-US';
  
  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }).format(date);
}

/**
 * Generate comparison PDF for two properties
 */
export async function generateComparisonPDF(
  comparison: any,
  options: Partial<PDFOptions> = {},
  companyInfo?: CompanyInfo
): Promise<{ filePath: string; fileName: string }> {
  const pdfOptions: PDFOptions = {
    format: 'A4',
    orientation: 'landscape', // Better for comparison table
    margins: {
      top: '15mm',
      bottom: '15mm',
      left: '10mm',
      right: '10mm'
    },
    quality: 'standard',
    ...options
  };

  // Ensure output directory exists
  const outputDir = path.join(process.cwd(), 'storage', 'comparisons');
  if (!existsSync(outputDir)) {
    await mkdir(outputDir, { recursive: true });
  }

  // Generate HTML content for comparison
  const html = generateComparisonHTML(comparison, companyInfo);

  // Generate PDF using Puppeteer
  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--no-first-run',
      '--no-zygote',
      '--single-process',
      '--disable-extensions'
    ],
    executablePath: process.env.CHROME_BIN || undefined
  });

  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0' });

    // Generate filename
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[:.]/g, '-');
    const fileName = `comparison-${timestamp}.pdf`;
    const filePath = path.join(outputDir, fileName);

    // Generate PDF
    await page.pdf({
      path: filePath,
      format: pdfOptions.format,
      landscape: pdfOptions.orientation === 'landscape',
      margin: pdfOptions.margins,
      printBackground: true,
      preferCSSPageSize: true
    });

    return {
      filePath,
      fileName
    };

  } finally {
    await browser.close();
  }
}

/**
 * Generate HTML for property comparison
 */
function generateComparisonHTML(comparison: any, companyInfo?: CompanyInfo): string {
  // This is a simplified version - you can expand this with full comparison styling
  return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Property Comparison</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .comparison-table { width: 100%; border-collapse: collapse; }
        .comparison-table th, .comparison-table td { 
            border: 1px solid #ddd; 
            padding: 12px; 
            text-align: left; 
        }
        .comparison-table th { background-color: #f2f2f2; }
        .advantage { background-color: #e8f5e8; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Property Comparison Report</h1>
        <p>Generated on ${new Date().toLocaleDateString()}</p>
    </div>
    
    <table class="comparison-table">
        <tr>
            <th>Feature</th>
            <th>Property 1</th>
            <th>Property 2</th>
            <th>Advantage</th>
        </tr>
        <tr>
            <td>Title</td>
            <td>${comparison.property1.title}</td>
            <td>${comparison.property2.title}</td>
            <td>-</td>
        </tr>
        <tr>
            <td>Price</td>
            <td>${comparison.property1.price.toLocaleString()} DZD</td>
            <td>${comparison.property2.price.toLocaleString()} DZD</td>
            <td class="${comparison.analysis.price.advantage === 'property1' ? 'advantage' : ''}">${comparison.analysis.price.advantage}</td>
        </tr>
        <tr>
            <td>Area</td>
            <td>${comparison.property1.area} m²</td>
            <td>${comparison.property2.area} m²</td>
            <td class="${comparison.analysis.area.advantage === 'property1' ? 'advantage' : ''}">${comparison.analysis.area.advantage}</td>
        </tr>
        <!-- Add more rows as needed -->
    </table>
    
    <div style="margin-top: 30px;">
        <h3>Recommendation</h3>
        <p>${comparison.overallRecommendation}</p>
    </div>
</body>
</html>
`;
} 

/**
 * Generate professional comparison PDF with advanced analytics
 */
export async function generateProfessionalComparisonPDF(
  comparison: any,
  options: Partial<PDFOptions> = {},
  companyInfo?: CompanyInfo
): Promise<{ filePath: string; fileName: string }> {
  const pdfOptions: PDFOptions = {
    format: 'A4',
    orientation: 'portrait', // Professional reports are typically portrait
    margins: {
      top: '15mm',
      bottom: '15mm',
      left: '15mm',
      right: '15mm'
    },
    quality: 'high', // High quality for professional reports
    ...options
  };

  // Ensure output directory exists
  const outputDir = path.join(process.cwd(), 'storage', 'professional-comparisons');
  if (!existsSync(outputDir)) {
    await mkdir(outputDir, { recursive: true });
  }

  // Generate HTML content for professional comparison
  const html = generateProfessionalComparisonHTML(comparison, companyInfo);

  // Generate PDF using Puppeteer
  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--no-first-run',
      '--no-zygote',
      '--single-process',
      '--disable-extensions',
      '--disable-web-security'
    ],
    executablePath: process.env.CHROME_BIN || undefined
  });

  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0' });

    // Generate filename
    const timestamp = new Date().toISOString().slice(0, 19).replace(/[:.]/g, '-');
    const fileName = `professional-comparison-${timestamp}.pdf`;
    const filePath = path.join(outputDir, fileName);

    // Generate PDF
    await page.pdf({
      path: filePath,
      format: pdfOptions.format,
      landscape: pdfOptions.orientation === 'landscape',
      margin: pdfOptions.margins,
      printBackground: true,
      preferCSSPageSize: true
    });

    return {
      filePath,
      fileName
    };

  } finally {
    await browser.close();
  }
}

/**
 * Generate professional comparison HTML
 */
function generateProfessionalComparisonHTML(comparison: any, companyInfo?: CompanyInfo): string {
  const prop1 = comparison.property1;
  const prop2 = comparison.property2;
  const analysis = comparison.comparison;

  return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Professional Property Comparison Report</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: "Segoe UI", Arial, sans-serif;
            font-size: 11px;
            line-height: 1.4;
            color: #2c3e50;
            background: #fff;
        }
        
        .report-container {
            max-width: 210mm;
            margin: 0 auto;
            padding: 20px;
            background: white;
        }
        
        /* Header Styles */
        .report-header {
            border-bottom: 4px solid #3498db;
            padding-bottom: 20px;
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .company-info h1 {
            color: #3498db;
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .company-details {
            color: #7f8c8d;
            font-size: 10px;
        }
        
        .report-title {
            text-align: right;
        }
        
        .report-title h2 {
            color: #2c3e50;
            font-size: 18px;
            margin-bottom: 5px;
        }
        
        .report-date {
            color: #7f8c8d;
            font-size: 10px;
        }
        
        /* Executive Summary */
        .executive-summary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            margin-bottom: 30px;
            border-radius: 10px;
        }
        
        .executive-summary h3 {
            font-size: 16px;
            margin-bottom: 15px;
            text-align: center;
        }
        
        .recommendation-box {
            background: rgba(255,255,255,0.1);
            padding: 15px;
            border-radius: 8px;
            margin-top: 15px;
        }
        
        .confidence-badge {
            display: inline-block;
            background: #27ae60;
            color: white;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 10px;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        /* Property Overview */
        .properties-overview {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .property-card {
            border: 2px solid #ecf0f1;
            border-radius: 10px;
            padding: 20px;
            position: relative;
        }
        
        .property-card.recommended {
            border-color: #27ae60;
            background: linear-gradient(135deg, #a8e6cf 0%, #dcedc8 100%);
        }
        
        .recommended-badge {
            position: absolute;
            top: -10px;
            right: 20px;
            background: #27ae60;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 10px;
            font-weight: bold;
        }
        
        .property-title {
            font-size: 14px;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
        }
        
        .property-specs {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
            margin-bottom: 15px;
        }
        
        .spec-item {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
            border-bottom: 1px dotted #bdc3c7;
        }
        
        .spec-label {
            color: #7f8c8d;
            font-weight: 500;
        }
        
        .spec-value {
            font-weight: bold;
            color: #2c3e50;
        }
        
        /* Investment Analysis */
        .analysis-section {
            margin-bottom: 30px;
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
        }
        
        .section-title {
            font-size: 14px;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 15px;
            padding-bottom: 5px;
            border-bottom: 2px solid #3498db;
        }
        
        .comparison-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .comparison-table th {
            background: #34495e;
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            font-size: 11px;
        }
        
        .comparison-table td {
            padding: 10px 12px;
            border-bottom: 1px solid #ecf0f1;
            font-size: 11px;
        }
        
        .comparison-table tr:nth-child(even) {
            background: #f8f9fa;
        }
        
        .advantage {
            background: #d5f4e6 !important;
            font-weight: bold;
            color: #27ae60;
        }
        
        .metric-value {
            font-weight: 600;
            color: #2c3e50;
        }
        
        /* Investment Grades */
        .grade-a { color: #27ae60; font-weight: bold; }
        .grade-b { color: #f39c12; font-weight: bold; }
        .grade-c { color: #e67e22; font-weight: bold; }
        .grade-d { color: #e74c3c; font-weight: bold; }
        
        /* Location Intelligence */
        .location-scores {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 15px;
            margin: 15px 0;
        }
        
        .score-circle {
            text-align: center;
        }
        
        .circle {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            margin: 0 auto 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 12px;
            color: white;
        }
        
        .score-excellent { background: #27ae60; }
        .score-good { background: #f39c12; }
        .score-average { background: #e67e22; }
        .score-poor { background: #e74c3c; }
        
        .score-label {
            font-size: 9px;
            font-weight: 500;
            color: #7f8c8d;
            text-align: center;
        }
        
        /* Risk Assessment */
        .risk-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .risk-box {
            background: white;
            border-radius: 8px;
            padding: 15px;
            border-left: 4px solid #e74c3c;
        }
        
        .risk-box.opportunity {
            border-left-color: #27ae60;
        }
        
        .risk-list {
            list-style: none;
            padding: 0;
        }
        
        .risk-list li {
            padding: 5px 0;
            position: relative;
            padding-left: 15px;
        }
        
        .risk-list li:before {
            content: "⚠️";
            position: absolute;
            left: 0;
        }
        
        .opportunity-list li:before {
            content: "💡";
        }
        
        /* Professional Insights */
        .insights-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        
        .insights-title {
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 10px;
            text-align: center;
        }
        
        .action-plan {
            background: rgba(255,255,255,0.1);
            padding: 15px;
            border-radius: 8px;
            margin-top: 15px;
        }
        
        .action-plan ol {
            padding-left: 20px;
        }
        
        .action-plan li {
            margin: 5px 0;
        }
        
        /* Footer */
        .report-footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #ecf0f1;
            text-align: center;
            color: #7f8c8d;
            font-size: 10px;
        }
        
        .disclaimer {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            font-size: 10px;
            color: #856404;
        }
        
        /* Responsive adjustments for PDF */
        @media print {
            .report-container { padding: 10px; }
            .analysis-section { page-break-inside: avoid; }
            .property-card { page-break-inside: avoid; }
        }
        
        /* Utility classes */
        .text-center { text-align: center; }
        .text-right { text-align: right; }
        .font-bold { font-weight: bold; }
        .text-success { color: #27ae60; }
        .text-warning { color: #f39c12; }
        .text-danger { color: #e74c3c; }
        .mb-10 { margin-bottom: 10px; }
        .mb-15 { margin-bottom: 15px; }
        .mb-20 { margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="report-container">
        <!-- Header -->
        <div class="report-header">
            <div class="company-info">
                <h1>${companyInfo?.name || 'Smart Real Estate Algeria'}</h1>
                <div class="company-details">
                    ${companyInfo?.address || 'Algiers, Algeria'}<br>
                    ${companyInfo?.phone || '+213 XXX XXX XXX'} • ${companyInfo?.email || 'contact@realestate.dz'}
                </div>
            </div>
            <div class="report-title">
                <h2>Professional Property Analysis</h2>
                <div class="report-date">Generated: ${new Date().toLocaleDateString('fr-FR', {
                  year: 'numeric',
                  month: 'long', 
                  day: 'numeric'
                })}</div>
            </div>
        </div>

        <!-- Executive Summary -->
        <div class="executive-summary">
            <h3>🎯 Executive Summary</h3>
            <div class="confidence-badge">${analysis.professionalRecommendation.confidenceLevel} Confidence</div>
            <div><strong>Recommended Property:</strong> ${analysis.professionalRecommendation.recommendedProperty === 'property1' ? prop1.title : prop2.title}</div>
            <div class="recommendation-box">
                <strong>Strategic Recommendation:</strong><br>
                ${analysis.professionalRecommendation.reasoning}
            </div>
        </div>

        <!-- Properties Overview -->
        <div class="properties-overview">
            <div class="property-card ${analysis.professionalRecommendation.recommendedProperty === 'property1' ? 'recommended' : ''}">
                ${analysis.professionalRecommendation.recommendedProperty === 'property1' ? '<div class="recommended-badge">RECOMMENDED</div>' : ''}
                <div class="property-title">${prop1.title}</div>
                <div class="property-specs">
                    <div class="spec-item">
                        <span class="spec-label">Price:</span>
                        <span class="spec-value">${prop1.price.toLocaleString()} DZD</span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Area:</span>
                        <span class="spec-value">${prop1.area} m²</span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Rooms:</span>
                        <span class="spec-value">${prop1.rooms}</span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Location:</span>
                        <span class="spec-value">${prop1.city}, ${prop1.wilaya}</span>
                    </div>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Investment Grade:</span>
                    <span class="spec-value grade-${prop1.marketAnalysis.investmentAnalysis.investmentGrade.toLowerCase().charAt(0)}">${prop1.marketAnalysis.investmentAnalysis.investmentGrade}</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Expected ROI:</span>
                    <span class="spec-value text-success">${(prop1.marketAnalysis.investmentAnalysis.expectedROI * 100).toFixed(1)}%</span>
                </div>
            </div>

            <div class="property-card ${analysis.professionalRecommendation.recommendedProperty === 'property2' ? 'recommended' : ''}">
                ${analysis.professionalRecommendation.recommendedProperty === 'property2' ? '<div class="recommended-badge">RECOMMENDED</div>' : ''}
                <div class="property-title">${prop2.title}</div>
                <div class="property-specs">
                    <div class="spec-item">
                        <span class="spec-label">Price:</span>
                        <span class="spec-value">${prop2.price.toLocaleString()} DZD</span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Area:</span>
                        <span class="spec-value">${prop2.area} m²</span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Rooms:</span>
                        <span class="spec-value">${prop2.rooms}</span>
                    </div>
                    <div class="spec-item">
                        <span class="spec-label">Location:</span>
                        <span class="spec-value">${prop2.city}, ${prop2.wilaya}</span>
                    </div>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Investment Grade:</span>
                    <span class="spec-value grade-${prop2.marketAnalysis.investmentAnalysis.investmentGrade.toLowerCase().charAt(0)}">${prop2.marketAnalysis.investmentAnalysis.investmentGrade}</span>
                </div>
                <div class="spec-item">
                    <span class="spec-label">Expected ROI:</span>
                    <span class="spec-value text-success">${(prop2.marketAnalysis.investmentAnalysis.expectedROI * 100).toFixed(1)}%</span>
                </div>
            </div>
        </div>

        <!-- Financial Analysis -->
        <div class="analysis-section">
            <div class="section-title">💰 Financial Analysis</div>
            <table class="comparison-table">
                <thead>
                    <tr>
                        <th>Metric</th>
                        <th>Property 1</th>
                        <th>Property 2</th>
                        <th>Advantage</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Price per m²</strong></td>
                        <td class="metric-value ${analysis.financialAnalysis.pricePerSqm.advantage === 'property1' ? 'advantage' : ''}">${analysis.financialAnalysis.pricePerSqm.property1.toLocaleString()} DZD</td>
                        <td class="metric-value ${analysis.financialAnalysis.pricePerSqm.advantage === 'property2' ? 'advantage' : ''}">${analysis.financialAnalysis.pricePerSqm.property2.toLocaleString()} DZD</td>
                        <td class="advantage">${analysis.financialAnalysis.pricePerSqm.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                    <tr>
                        <td><strong>Total Cost of Ownership</strong></td>
                        <td class="metric-value ${analysis.financialAnalysis.totalCost.advantage === 'property1' ? 'advantage' : ''}">${analysis.financialAnalysis.totalCost.property1.toLocaleString()} DZD</td>
                        <td class="metric-value ${analysis.financialAnalysis.totalCost.advantage === 'property2' ? 'advantage' : ''}">${analysis.financialAnalysis.totalCost.property2.toLocaleString()} DZD</td>
                        <td class="advantage">${analysis.financialAnalysis.totalCost.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                    <tr>
                        <td><strong>Market Positioning</strong></td>
                        <td class="metric-value">${analysis.financialAnalysis.marketPositioning.property1}</td>
                        <td class="metric-value">${analysis.financialAnalysis.marketPositioning.property2}</td>
                        <td>Contextual</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Investment Analysis -->
        <div class="analysis-section">
            <div class="section-title">📈 Investment Analysis</div>
            <table class="comparison-table">
                <thead>
                    <tr>
                        <th>Investment Metric</th>
                        <th>Property 1</th>
                        <th>Property 2</th>
                        <th>Advantage</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Expected ROI</strong></td>
                        <td class="metric-value ${analysis.investmentAnalysis.expectedROI.advantage === 'property1' ? 'advantage' : ''}">${(analysis.investmentAnalysis.expectedROI.property1 * 100).toFixed(1)}%</td>
                        <td class="metric-value ${analysis.investmentAnalysis.expectedROI.advantage === 'property2' ? 'advantage' : ''}">${(analysis.investmentAnalysis.expectedROI.property2 * 100).toFixed(1)}%</td>
                        <td class="advantage">${analysis.investmentAnalysis.expectedROI.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                    <tr>
                        <td><strong>Rental Yield</strong></td>
                        <td class="metric-value ${analysis.investmentAnalysis.rentalYield.advantage === 'property1' ? 'advantage' : ''}">${(analysis.investmentAnalysis.rentalYield.property1 * 100).toFixed(1)}%</td>
                        <td class="metric-value ${analysis.investmentAnalysis.rentalYield.advantage === 'property2' ? 'advantage' : ''}">${(analysis.investmentAnalysis.rentalYield.property2 * 100).toFixed(1)}%</td>
                        <td class="advantage">${analysis.investmentAnalysis.rentalYield.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                    <tr>
                        <td><strong>Investment Grade</strong></td>
                        <td class="metric-value grade-${analysis.investmentAnalysis.investmentGrade.property1.toLowerCase().charAt(0)}">${analysis.investmentAnalysis.investmentGrade.property1}</td>
                        <td class="metric-value grade-${analysis.investmentAnalysis.investmentGrade.property2.toLowerCase().charAt(0)}">${analysis.investmentAnalysis.investmentGrade.property2}</td>
                        <td>Grade-based</td>
                    </tr>
                    <tr>
                        <td><strong>5-Year Appreciation</strong></td>
                        <td class="metric-value ${analysis.investmentAnalysis.appreciation5Year.advantage === 'property1' ? 'advantage' : ''}">${analysis.investmentAnalysis.appreciation5Year.property1.toLocaleString()} DZD</td>
                        <td class="metric-value ${analysis.investmentAnalysis.appreciation5Year.advantage === 'property2' ? 'advantage' : ''}">${analysis.investmentAnalysis.appreciation5Year.property2.toLocaleString()} DZD</td>
                        <td class="advantage">${analysis.investmentAnalysis.appreciation5Year.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Location Intelligence -->
        <div class="analysis-section">
            <div class="section-title">📍 Location Intelligence</div>
            <div class="mb-15">
                <strong>Overall Location Scores:</strong>
                Property 1: ${(analysis.locationAnalysis.overallScore.property1 * 100).toFixed(0)}% | 
                Property 2: ${(analysis.locationAnalysis.overallScore.property2 * 100).toFixed(0)}%
                <span class="advantage" style="margin-left: 10px;">
                    ${analysis.locationAnalysis.overallScore.advantage === 'property1' ? 'Property 1 Superior' : 'Property 2 Superior'}
                </span>
            </div>
            
            <table class="comparison-table">
                <thead>
                    <tr>
                        <th>Location Factor</th>
                        <th>Property 1</th>
                        <th>Property 2</th>
                        <th>Advantage</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Schools</strong></td>
                        <td class="metric-value ${analysis.locationAnalysis.factorComparison.schools.advantage === 'property1' ? 'advantage' : ''}">${(analysis.locationAnalysis.factorComparison.schools.property1 * 100).toFixed(0)}%</td>
                        <td class="metric-value ${analysis.locationAnalysis.factorComparison.schools.advantage === 'property2' ? 'advantage' : ''}">${(analysis.locationAnalysis.factorComparison.schools.property2 * 100).toFixed(0)}%</td>
                        <td class="advantage">${analysis.locationAnalysis.factorComparison.schools.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                    <tr>
                        <td><strong>Transportation</strong></td>
                        <td class="metric-value ${analysis.locationAnalysis.factorComparison.transport.advantage === 'property1' ? 'advantage' : ''}">${(analysis.locationAnalysis.factorComparison.transport.property1 * 100).toFixed(0)}%</td>
                        <td class="metric-value ${analysis.locationAnalysis.factorComparison.transport.advantage === 'property2' ? 'advantage' : ''}">${(analysis.locationAnalysis.factorComparison.transport.property2 * 100).toFixed(0)}%</td>
                        <td class="advantage">${analysis.locationAnalysis.factorComparison.transport.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                    <tr>
                        <td><strong>Amenities</strong></td>
                        <td class="metric-value ${analysis.locationAnalysis.factorComparison.amenities.advantage === 'property1' ? 'advantage' : ''}">${(analysis.locationAnalysis.factorComparison.amenities.property1 * 100).toFixed(0)}%</td>
                        <td class="metric-value ${analysis.locationAnalysis.factorComparison.amenities.advantage === 'property2' ? 'advantage' : ''}">${(analysis.locationAnalysis.factorComparison.amenities.property2 * 100).toFixed(0)}%</td>
                        <td class="advantage">${analysis.locationAnalysis.factorComparison.amenities.advantage === 'property1' ? 'Property 1' : 'Property 2'}</td>
                    </tr>
                    <tr>
                        <td><strong>Neighborhood Ranking</strong></td>
                        <td class="metric-value">${analysis.locationAnalysis.neighborhoodRanking.property1}</td>
                        <td class="metric-value">${analysis.locationAnalysis.neighborhoodRanking.property2}</td>
                        <td>Qualitative</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Risk Assessment -->
        <div class="analysis-section">
            <div class="section-title">⚖️ Risk Assessment</div>
            <div class="risk-grid">
                <div class="risk-box">
                    <h4 class="mb-10">🚨 Risk Factors - Property 1</h4>
                    <ul class="risk-list">
                        ${analysis.riskAssessment.property1Risks.map((risk: string) => `<li>${risk}</li>`).join('')}
                    </ul>
                </div>
                <div class="risk-box">
                    <h4 class="mb-10">🚨 Risk Factors - Property 2</h4>
                    <ul class="risk-list">
                        ${analysis.riskAssessment.property2Risks.map((risk: string) => `<li>${risk}</li>`).join('')}
                    </ul>
                </div>
            </div>
            <div class="text-center mb-15">
                <strong>Lower Risk Investment:</strong> 
                <span class="advantage">${analysis.riskAssessment.riskAssessment.lowerRisk === 'property1' ? 'Property 1' : 'Property 2'}</span>
                (${analysis.riskAssessment.riskAssessment.property1} vs ${analysis.riskAssessment.riskAssessment.property2} risk factors)
            </div>
        </div>

        <!-- Professional Insights -->
        <div class="insights-box">
            <div class="insights-title">💡 Professional Strategic Insights</div>
            <div><strong>Market Position:</strong> ${analysis.professionalRecommendation.reasoning}</div>
            
            <div class="action-plan">
                <strong>📋 Action Plan:</strong>
                <ol>
                    ${analysis.professionalRecommendation.actionPlan.map((action: string) => `<li>${action}</li>`).join('')}
                </ol>
            </div>
            
            <div style="margin-top: 15px;">
                <strong>Next Steps:</strong> ${analysis.professionalRecommendation.nextSteps}
            </div>
        </div>

        <!-- Disclaimer -->
        <div class="disclaimer">
            <strong>Professional Disclaimer:</strong> This analysis is based on current market data and statistical models. 
            Property investments carry inherent risks and market conditions may change. 
            This report should be used in conjunction with professional real estate advice, legal consultation, and personal financial planning. 
            Past performance does not guarantee future results.
        </div>

        <!-- Footer -->
        <div class="report-footer">
            <div><strong>Smart Real Estate Algeria - Professional Property Analysis</strong></div>
            <div>Generated: ${new Date().toLocaleString('fr-FR')} | Report ID: RPT-${Date.now()}</div>
            <div>This report contains confidential and proprietary market intelligence</div>
        </div>
    </div>
</body>
</html>
`;
} 