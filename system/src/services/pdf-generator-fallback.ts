/**
 * Fallback PDF Generation Service
 * 
 * Alternative PDF generation when Puppeteer is not available
 * Uses HTML generation with download links for manual PDF conversion
 */

import { PropertyQuote, formatCurrency } from './quote-generator';
import { mkdir, writeFile } from 'fs/promises';
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
 * Generate HTML file for quote (fallback when PDF generation fails)
 */
export async function generateQuoteHTMLFile(
  quote: PropertyQuote,
  options: Partial<PDFOptions> = {},
  companyInfo?: CompanyInfo
): Promise<{ filePath: string; fileName: string; downloadUrl: string }> {
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
  const outputDir = path.join(process.cwd(), 'storage', 'quotes-html');
  if (!existsSync(outputDir)) {
    await mkdir(outputDir, { recursive: true });
  }

  // Generate HTML content
  const html = generateQuoteHTML(quote, companyInfo, pdfOptions);

  // Generate filename
  const fileName = `quote-${quote.quoteNumber}.html`;
  const filePath = path.join(outputDir, fileName);

  // Write HTML file
  await writeFile(filePath, html, 'utf8');

  return {
    filePath,
    fileName,
    downloadUrl: `/uploads/quotes-html/${fileName}`
  };
}

/**
 * Generate HTML content for the quote with print-friendly styling
 */
function generateQuoteHTML(quote: PropertyQuote, companyInfo?: CompanyInfo, options?: PDFOptions): string {
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
        @media print {
            @page {
                size: ${options?.format || 'A4'} ${options?.orientation || 'portrait'};
                margin: ${options?.margins?.top || '20mm'} ${options?.margins?.right || '15mm'} ${options?.margins?.bottom || '20mm'} ${options?.margins?.left || '15mm'};
            }
            body { margin: 0; }
            .no-print { display: none !important; }
        }
        
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
        
        .property-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .property-item {
            background: #f8fafc;
            padding: 15px;
            border-radius: 6px;
            border-left: 4px solid #2563eb;
        }
        
        .property-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
        }
        
        .property-value {
            font-size: 14px;
            font-weight: 600;
            color: #374151;
        }
        
        .pricing-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        
        .pricing-table th,
        .pricing-table td {
            padding: 12px;
            text-align: ${isRTL ? 'right' : 'left'};
            border-bottom: 1px solid #e5e7eb;
        }
        
        .pricing-table th {
            background: #f8fafc;
            font-weight: 600;
            color: #374151;
        }
        
        .pricing-table .total-row {
            background: #2563eb;
            color: white;
            font-weight: bold;
        }
        
        .pricing-table .total-row td {
            border-bottom: none;
        }
        
        .terms-section {
            margin-bottom: 30px;
            background: #f8fafc;
            padding: 20px;
            border-radius: 8px;
        }
        
        .terms-list {
            list-style: none;
            padding: 0;
        }
        
        .terms-list li {
            margin-bottom: 8px;
            padding-left: 20px;
            position: relative;
        }
        
        .terms-list li:before {
            content: "•";
            color: #2563eb;
            font-weight: bold;
            position: absolute;
            left: 0;
        }
        
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            text-align: center;
            font-size: 12px;
            color: #666;
        }
        
        .print-instructions {
            background: #fef3c7;
            border: 1px solid #f59e0b;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .print-instructions h3 {
            color: #92400e;
            margin-bottom: 10px;
        }
        
        .print-instructions p {
            color: #92400e;
            margin-bottom: 5px;
        }
    </style>
</head>
<body>
    <div class="print-instructions no-print">
        <h3>📄 Print Instructions</h3>
        <p>Press Ctrl+P (or Cmd+P on Mac) to print this quote as PDF</p>
        <p>Make sure to select "Save as PDF" in your browser's print dialog</p>
    </div>
    
    <div class="header">
        <div class="company-info">
            <div class="company-name">${companyInfo?.name || getLocalizedText('companyName', language)}</div>
            <div class="company-details">
                ${companyInfo?.address || getLocalizedText('companyAddress', language)}<br>
                ${getLocalizedText('phone', language)}: ${companyInfo?.phone || getLocalizedText('companyPhone', language)}<br>
                ${getLocalizedText('email', language)}: ${companyInfo?.email || getLocalizedText('companyEmail', language)}
                ${companyInfo?.website ? `<br>${getLocalizedText('website', language)}: ${companyInfo.website}` : ''}
                ${companyInfo?.taxId ? `<br>${getLocalizedText('taxId', language)}: ${companyInfo.taxId}` : ''}
            </div>
        </div>
        <div class="quote-info">
            <div class="quote-number">${getLocalizedText('quoteNumber', language)}: ${quote.quoteNumber}</div>
            <div class="quote-date">${getLocalizedText('date', language)}: ${formatDate(new Date(), language)}</div>
            <div class="quote-date">${getLocalizedText('validUntil', language)}: ${formatDate(quote.terms.validUntil, language)}</div>
        </div>
    </div>
    
    <div class="client-section">
        <div class="section-title">${getLocalizedText('clientInformation', language)}</div>
        <div class="property-grid">
            <div class="property-item">
                <div class="property-label">${getLocalizedText('name', language)}</div>
                <div class="property-value">${quote.contact.name}</div>
            </div>
            <div class="property-item">
                <div class="property-label">${getLocalizedText('email', language)}</div>
                <div class="property-value">${quote.contact.email}</div>
            </div>
            ${quote.contact.phone ? `
            <div class="property-item">
                <div class="property-label">${getLocalizedText('phone', language)}</div>
                <div class="property-value">${quote.contact.phone}</div>
            </div>
            ` : ''}
            <div class="property-item">
                <div class="property-label">${getLocalizedText('type', language)}</div>
                <div class="property-value">${getLocalizedText(quote.contact.type.toLowerCase(), language)}</div>
            </div>
        </div>
    </div>
    
    <div class="property-details">
        <div class="section-title">${getLocalizedText('propertyDetails', language)}</div>
        <div class="property-grid">
            <div class="property-item">
                <div class="property-label">${getLocalizedText('title', language)}</div>
                <div class="property-value">${quote.property.title}</div>
            </div>
            <div class="property-item">
                <div class="property-label">${getLocalizedText('type', language)}</div>
                <div class="property-value">${getLocalizedText(quote.property.propertyType.toLowerCase(), language)}</div>
            </div>
            <div class="property-item">
                <div class="property-label">${getLocalizedText('location', language)}</div>
                <div class="property-value">${quote.property.city}, ${quote.property.wilaya}</div>
            </div>
            <div class="property-item">
                <div class="property-label">${getLocalizedText('area', language)}</div>
                <div class="property-value">${quote.property.area} m²</div>
            </div>
            <div class="property-item">
                <div class="property-label">${getLocalizedText('rooms', language)}</div>
                <div class="property-value">${quote.property.rooms}</div>
            </div>
            <div class="property-item">
                <div class="property-label">${getLocalizedText('condition', language)}</div>
                <div class="property-value">${getLocalizedText(quote.property.condition.toLowerCase(), language)}</div>
            </div>
        </div>
    </div>
    
    <div class="pricing-section">
        <div class="section-title">${getLocalizedText('pricingBreakdown', language)}</div>
        <table class="pricing-table">
            <thead>
                <tr>
                    <th>${getLocalizedText('item', language)}</th>
                    <th>${getLocalizedText('quantity', language)}</th>
                    <th>${getLocalizedText('unitPrice', language)}</th>
                    <th>${getLocalizedText('total', language)}</th>
                </tr>
            </thead>
            <tbody>
                ${quote.pricing.items.map(item => `
                <tr>
                    <td>${item.description}</td>
                    <td>${item.quantity}</td>
                    <td>${formatCurrency(item.unitPrice, quote.currency)}</td>
                    <td>${formatCurrency(item.total, quote.currency)}</td>
                </tr>
                `).join('')}
                <tr class="total-row">
                    <td colspan="3">${getLocalizedText('total', language)}</td>
                    <td>${formatCurrency(quote.pricing.totalAmount, quote.currency)}</td>
                </tr>
            </tbody>
        </table>
    </div>
    
    <div class="terms-section">
        <div class="section-title">${getLocalizedText('termsAndConditions', language)}</div>
        <ul class="terms-list">
            ${quote.terms.conditions.map(condition => `<li>${condition}</li>`).join('')}
        </ul>
    </div>
    
    <div class="footer">
        <p>${getLocalizedText('footerText', language)}</p>
        <p>${getLocalizedText('generatedOn', language)}: ${formatDate(new Date(), language)}</p>
    </div>
</body>
</html>
`;
}

/**
 * Get localized text based on language
 */
function getLocalizedText(key: string, language: 'ar' | 'fr' | 'en'): string {
  const translations = {
    ar: {
      companyName: 'شركة العقارات الذكية',
      companyAddress: 'الجزائر العاصمة، الجزائر',
      companyPhone: '+213 123 456 789',
      companyEmail: 'info@smartcontact.dz',
      phone: 'الهاتف',
      email: 'البريد الإلكتروني',
      website: 'الموقع الإلكتروني',
      taxId: 'الرقم الضريبي',
      quoteNumber: 'رقم العرض',
      date: 'التاريخ',
      validUntil: 'صالح حتى',
      clientInformation: 'معلومات العميل',
      name: 'الاسم',
      type: 'النوع',
      propertyDetails: 'تفاصيل العقار',
      title: 'العنوان',
      location: 'الموقع',
      area: 'المساحة',
      rooms: 'الغرف',
      condition: 'الحالة',
      pricingBreakdown: 'تفصيل الأسعار',
      item: 'البند',
      quantity: 'الكمية',
      unitPrice: 'سعر الوحدة',
      total: 'المجموع',
      termsAndConditions: 'الشروط والأحكام',
      footerText: 'هذا العرض صالح لمدة 30 يوماً من تاريخ الإصدار',
      generatedOn: 'تم إنشاؤه في',
      buyer: 'مشتري',
      tenant: 'مستأجر',
      investor: 'مستثمر',
      apartment: 'شقة',
      villa: 'فيلا',
      house: 'منزل',
      office: 'مكتب',
      shop: 'متجر',
      warehouse: 'مستودع',
      land: 'أرض',
      garage: 'كراج',
      poor: 'رديء',
      fair: 'مقبول',
      good: 'جيد',
      excellent: 'ممتاز',
      new: 'جديد'
    },
    fr: {
      companyName: 'Smart Contact Immobilier',
      companyAddress: 'Alger, Algérie',
      companyPhone: '+213 123 456 789',
      companyEmail: 'info@smartcontact.dz',
      phone: 'Téléphone',
      email: 'Email',
      website: 'Site web',
      taxId: 'Numéro fiscal',
      quoteNumber: 'Numéro de devis',
      date: 'Date',
      validUntil: 'Valide jusqu\'au',
      clientInformation: 'Informations client',
      name: 'Nom',
      type: 'Type',
      propertyDetails: 'Détails du bien',
      title: 'Titre',
      location: 'Localisation',
      area: 'Surface',
      rooms: 'Pièces',
      condition: 'État',
      pricingBreakdown: 'Détail des prix',
      item: 'Article',
      quantity: 'Quantité',
      unitPrice: 'Prix unitaire',
      total: 'Total',
      termsAndConditions: 'Conditions générales',
      footerText: 'Ce devis est valable 30 jours à compter de la date d\'émission',
      generatedOn: 'Généré le',
      buyer: 'Acheteur',
      tenant: 'Locataire',
      investor: 'Investisseur',
      apartment: 'Appartement',
      villa: 'Villa',
      house: 'Maison',
      office: 'Bureau',
      shop: 'Commerce',
      warehouse: 'Entrepôt',
      land: 'Terrain',
      garage: 'Garage',
      poor: 'Mauvais',
      fair: 'Moyen',
      good: 'Bon',
      excellent: 'Excellent',
      new: 'Neuf'
    },
    en: {
      companyName: 'Smart Contact Real Estate',
      companyAddress: 'Algiers, Algeria',
      companyPhone: '+213 123 456 789',
      companyEmail: 'info@smartcontact.dz',
      phone: 'Phone',
      email: 'Email',
      website: 'Website',
      taxId: 'Tax ID',
      quoteNumber: 'Quote Number',
      date: 'Date',
      validUntil: 'Valid Until',
      clientInformation: 'Client Information',
      name: 'Name',
      type: 'Type',
      propertyDetails: 'Property Details',
      title: 'Title',
      location: 'Location',
      area: 'Area',
      rooms: 'Rooms',
      condition: 'Condition',
      pricingBreakdown: 'Pricing Breakdown',
      item: 'Item',
      quantity: 'Quantity',
      unitPrice: 'Unit Price',
      total: 'Total',
      termsAndConditions: 'Terms and Conditions',
      footerText: 'This quote is valid for 30 days from the date of issue',
      generatedOn: 'Generated on',
      buyer: 'Buyer',
      tenant: 'Tenant',
      investor: 'Investor',
      apartment: 'Apartment',
      villa: 'Villa',
      house: 'House',
      office: 'Office',
      shop: 'Shop',
      warehouse: 'Warehouse',
      land: 'Land',
      garage: 'Garage',
      poor: 'Poor',
      fair: 'Fair',
      good: 'Good',
      excellent: 'Excellent',
      new: 'New'
    }
  };

  return translations[language][key] || key;
}

/**
 * Format date based on language
 */
function formatDate(date: Date, language: 'ar' | 'fr' | 'en'): string {
  const options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  };

  const locales = {
    ar: 'ar-DZ',
    fr: 'fr-DZ',
    en: 'en-US'
  };

  return date.toLocaleDateString(locales[language], options);
} 