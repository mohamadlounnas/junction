/**
 * Quote Management Routes for Algeria Real Estate
 * 
 * Provides comprehensive quote management including:
 * - Generate property quotes with pricing calculations
 * - CRUD operations for quotes
 * - PDF generation for quotes and comparisons
 * - Multi-language support
 * - Integration with recommendation system
 */

import { Elysia, t } from 'elysia';
import { generatePropertyQuote, formatCurrency } from '../services/quote-generator';
import { generateQuotePDF, generateComparisonPDF } from '../services/pdf-generator';
import { createReadStream, existsSync } from 'fs';
import path from 'path';

export const quotesRoutes = new Elysia({ prefix: '/quotes' })
  
  // Generate a new quote for a property
  .post('/generate', async ({ body }) => {
    try {
      const { propertyId, contactId, agentId, language = 'fr', customConfig } = body;

      // Generate the quote
      const quote = await generatePropertyQuote(
        propertyId,
        contactId,
        agentId,
        customConfig
      );

      return {
        success: true,
        quote: {
          quoteNumber: quote.quoteNumber,
          property: quote.property,
          contact: quote.contact,
          pricing: quote.pricing,
          terms: quote.terms,
          status: quote.status,
          language: quote.language,
          currency: quote.currency,
          createdAt: quote.createdAt,
          validUntil: quote.terms.validUntil
        }
      };

    } catch (error) {
      console.error('Quote generation error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to generate quote'
      };
    }
  }, {
    body: t.Object({
      propertyId: t.String(),
      contactId: t.Optional(t.String()),
      agentId: t.Optional(t.String()),
      language: t.Optional(t.Union([t.Literal('ar'), t.Literal('fr'), t.Literal('en')])),
      customConfig: t.Optional(t.Object({
        agentCommissionRate: t.Optional(t.Number()),
        legalFeesRate: t.Optional(t.Number()),
        administrativeFees: t.Optional(t.Number()),
        taxRate: t.Optional(t.Number()),
        validityDays: t.Optional(t.Number())
      }))
    }),
    detail: {
      tags: ['Quotes'],
      summary: 'Generate Property Quote',
      description: `
## 💰 Property Quote Generation

Generate comprehensive property quotes with detailed pricing breakdowns, fees, and terms.

### 🎯 Quote Features

#### **Automatic Calculations**
- Base property price
- Agent commission (configurable %)
- Legal fees (configurable %)
- Administrative fees (fixed amount)
- Taxes/VAT (configurable %)
- Total amount with all fees

#### **Multi-language Support**
- **Arabic**: Full RTL support with Arabic text
- **French**: Default language for Algeria
- **English**: International clients

#### **Customizable Parameters**
- Commission rates per transaction
- Fee structures by property type
- Validity periods
- Payment terms and conditions

#### **Professional Features**
- Unique quote numbering system
- Validity period tracking
- Terms and conditions
- Client information integration
- Property details inclusion

### 🇩🇿 Algeria Market Specifics

- **DZD Currency**: All calculations in Algerian Dinars
- **Local Regulations**: Compliant with Algerian real estate law
- **Market Rates**: Default rates based on local market standards
- **Cultural Considerations**: Arabic language support for local clients

### 📊 Response Structure

Returns complete quote object with:
- **Quote Details**: Number, dates, validity
- **Property Information**: Full property details
- **Client Information**: Contact details (if provided)
- **Pricing Breakdown**: Itemized costs and fees
- **Terms**: Payment terms and conditions
- **Status**: Quote status tracking

### 🎯 Use Cases

#### **Real Estate Agents**
- Generate client quotes instantly
- Professional presentation materials
- Pricing transparency and breakdown
- Multi-language client support

#### **Property Developers**
- Standardized pricing presentation
- Fee structure transparency
- Professional documentation
- Regulatory compliance

#### **Investors**
- Total cost analysis
- ROI calculations support
- Professional documentation
- Due diligence materials
      `
    }
  })

  // Generate PDF for a quote
  .post('/pdf', async ({ body }) => {
    try {
      const { 
        propertyId, 
        contactId, 
        agentId, 
        language = 'fr',
        format,
        orientation,
        companyInfo
      } = body;

      // Handle format and orientation with defaults
      const pdfFormat = (format === 'A4' || format === 'Letter') ? format : 'A4';
      const pdfOrientation = (orientation === 'portrait' || orientation === 'landscape') ? orientation : 'portrait';
      
      // Filter out empty company info fields
      const cleanCompanyInfo = companyInfo ? {
        name: companyInfo.name || '',
        address: companyInfo.address || '',
        phone: companyInfo.phone || '',
        email: companyInfo.email || '',
        website: companyInfo.website || '',
        taxId: companyInfo.taxId || ''
      } : undefined;

      // Generate the quote first
      const quote = await generatePropertyQuote(propertyId, contactId, agentId, { language });

      // Generate PDF
      const { filePath, fileName } = await generateQuotePDF(
        quote,
        { format: pdfFormat, orientation: pdfOrientation },
        cleanCompanyInfo
      );

      return {
        success: true,
        pdf: {
          fileName,
          downloadUrl: `/api/quotes/download/${fileName}`,
          quote: {
            quoteNumber: quote.quoteNumber,
            totalAmount: quote.pricing.totalAmount,
            currency: quote.currency,
            validUntil: quote.terms.validUntil
          }
        }
      };

    } catch (error) {
      console.error('PDF generation error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to generate PDF'
      };
    }
  }, {
    body: t.Object({
      propertyId: t.String(),
      contactId: t.Optional(t.String()),
      agentId: t.Optional(t.String()),
      language: t.Optional(t.Union([t.Literal('ar'), t.Literal('fr'), t.Literal('en')])),
      format: t.Optional(t.String()),
      orientation: t.Optional(t.String()),
      companyInfo: t.Optional(t.Object({
        name: t.Optional(t.String()),
        address: t.Optional(t.String()),
        phone: t.Optional(t.String()),
        email: t.Optional(t.String()),
        website: t.Optional(t.String()),
        taxId: t.Optional(t.String())
      }))
    }),
    detail: {
      tags: ['Quotes'],
      summary: 'Generate Quote PDF',
      description: `
## 📄 Professional Quote PDF Generation

Generate beautifully formatted PDF documents for property quotes with professional styling and multi-language support.

### 🎨 PDF Features

#### **Professional Design**
- Clean, modern layout
- Company branding integration
- Responsive design elements
- Print-optimized formatting

#### **Multi-language Layout**
- **Arabic**: Right-to-left (RTL) layout with Arabic fonts
- **French**: Standard left-to-right layout
- **English**: International formatting

#### **Customizable Format**
- **Paper Size**: A4 (default) or Letter
- **Orientation**: Portrait (default) or Landscape
- **Margins**: Optimized for printing
- **Quality**: Standard or High resolution

#### **Request Parameters**
- **format**: Optional string - "A4" or "Letter" (defaults to "A4" if empty or invalid)
- **orientation**: Optional string - "portrait" or "landscape" (defaults to "portrait" if empty or invalid)
- **companyInfo**: Optional object with company branding details (empty strings are converted to empty values)

#### **Content Sections**
- Company information and branding
- Quote number and validity dates
- Client information (if provided)
- Property details and specifications
- Detailed pricing breakdown
- Terms and conditions
- Footer with generation date

### 🏢 Company Branding

Customize PDFs with your company information:
- Company name and address
- Contact information (phone, email, website)
- Tax ID and registration numbers
- Logo integration (future feature)

### 📊 Pricing Presentation

Professional pricing tables with:
- Base property price
- Commission breakdown with percentages
- Legal and administrative fees
- Tax calculations
- Total amount highlighting
- Currency formatting (DZD)

### 🔐 Security Features

- Unique quote numbering
- Validity period enforcement
- Generation timestamps
- Audit trail support

### 📥 Download Management

- Instant download links
- File naming conventions
- Storage management
- Access control (future feature)
      `
    }
  })

  // Generate comparison PDF
  .post('/compare-pdf', async ({ body }) => {
    try {
      const { property1Id, property2Id, contactId, language = 'fr', companyInfo } = body;

      // Get the professional comparison data using the new system
      const { generateProfessionalComparison } = await import('../services/market-analysis');
      const professionalComparison = await generateProfessionalComparison(property1Id, property2Id, contactId);

      // Generate professional comparison PDF
      const { generateProfessionalComparisonPDF } = await import('../services/pdf-generator');
      const { filePath, fileName } = await generateProfessionalComparisonPDF(
        {
          property1: { 
            ...professionalComparison.property1, 
            marketAnalysis: professionalComparison.property1.analysis 
          },
          property2: { 
            ...professionalComparison.property2, 
            marketAnalysis: professionalComparison.property2.analysis 
          },
          comparison: professionalComparison.comparison
        },
        { orientation: 'portrait', quality: 'high' },
        companyInfo
      );

      return {
        success: true,
        pdf: {
          fileName,
          downloadUrl: `/api/quotes/download-comparison/${fileName}`,
          comparison: {
            property1: professionalComparison.property1.title,
            property2: professionalComparison.property2.title,
            recommendedProperty: professionalComparison.comparison.professionalRecommendation.recommendedProperty,
            confidenceLevel: professionalComparison.comparison.professionalRecommendation.confidenceLevel,
            recommendation: professionalComparison.comparison.professionalRecommendation.reasoning,
            analysisType: 'PROFESSIONAL'
          }
        }
      };

    } catch (error) {
      console.error('Professional comparison PDF generation error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to generate professional comparison PDF'
      };
    }
  }, {
    body: t.Object({
      property1Id: t.String(),
      property2Id: t.String(),
      contactId: t.Optional(t.String()),
      language: t.Optional(t.Union([t.Literal('ar'), t.Literal('fr'), t.Literal('en')])),
      companyInfo: t.Optional(t.Object({
        name: t.String(),
        address: t.String(),
        phone: t.String(),
        email: t.String(),
        website: t.Optional(t.String())
      }))
    }),
    detail: {
      tags: ['Quotes'],
      summary: 'Generate Professional Property Comparison PDF',
      description: `
## 🏆 Professional Property Comparison PDF Generation

**Advanced market analysis reports for professional real estate agents**

Generate comprehensive property comparison reports with professional-grade analytics, investment intelligence, location scoring, risk assessment, and strategic recommendations.

### 🎨 Professional Report Features

#### **📊 Executive Summary**
- High-confidence recommendations with confidence levels
- Strategic investment insights
- Key decision factors and advantages
- Professional recommendation reasoning

#### **💰 Financial Analysis**
- Price per square meter comparisons
- Total cost of ownership calculations
- Market positioning analysis
- Value-for-money assessments
- Investment grade ratings (A+ to D)

#### **📈 Investment Intelligence**
- Expected ROI calculations and projections
- Rental yield analysis with market data
- 1, 3, and 5-year appreciation forecasts
- Investment risk grading
- Payback period analysis

#### **📍 Location Intelligence**
- Comprehensive neighborhood scoring
- Schools, healthcare, transport analysis
- Amenity accessibility ratings
- Safety and infrastructure scores
- Regional ranking (Top 10%, 25%, 50%)

#### **⚖️ Risk Assessment**
- Identified risk factors for each property
- Market timing considerations
- Liquidity and resale analysis
- Investment risk mitigation strategies
- Opportunity identification

#### **🎯 Strategic Recommendations**
- Professional action plans
- Negotiation strategies
- Market timing advice
- Investment decision frameworks
- Next steps and implementation

### 🎨 Professional PDF Design

#### **Visual Excellence**
- Clean, modern professional layout
- Company branding integration
- Color-coded advantage highlighting
- Investment grade visual indicators
- Executive summary sections

#### **Data Visualization**
- Professional comparison tables
- Investment grade color coding
- Location intelligence scoring
- Risk factor presentations
- Confidence level indicators

#### **Professional Standards**
- Industry-standard terminology
- Regulatory compliance disclaimers
- Professional liability coverage
- Market intelligence confidentiality
- Report audit trails

### 🇩🇿 Algeria Market Specialization

#### **Local Market Intelligence**
- All 48 wilayas market data
- Regional growth rate analysis
- Cultural preference factors
- Local regulatory compliance
- DZD currency formatting

#### **Professional Credibility**
- Algeria real estate law compliance
- Local market benchmarking
- Regional investment expertise
- Cultural sensitivity considerations
- Professional presentation standards

### 📋 Report Sections

#### **1. Executive Summary**
- Confidence-rated recommendations
- Key strategic insights
- Critical decision factors
- Investment highlights

#### **2. Property Overview**
- Side-by-side comparison cards
- Investment grade indicators
- Key specifications
- Recommended property highlighting

#### **3. Financial Analysis**
- Comprehensive pricing comparison
- Cost of ownership analysis
- Market positioning assessment
- Value proposition evaluation

#### **4. Investment Analysis**
- ROI and yield comparisons
- Appreciation forecasts
- Investment grade analysis
- Performance projections

#### **5. Location Intelligence**
- Neighborhood scoring breakdown
- Amenity factor analysis
- Regional ranking comparison
- Accessibility assessments

#### **6. Risk Assessment**
- Risk factor identification
- Comparative risk analysis
- Mitigation recommendations
- Market timing considerations

#### **7. Professional Insights**
- Strategic recommendations
- Action plan development
- Implementation guidance
- Market positioning advice

### 🚀 Agent Benefits

#### **Client Confidence**
- Professional presentation materials
- Data-driven recommendations
- Objective analysis framework
- Investment justification

#### **Competitive Advantage**
- Advanced analytics capability
- Professional report generation
- Market intelligence access
- Strategic advisory services

#### **Time Efficiency**
- Automated analysis generation
- Professional formatting
- Comprehensive data integration
- Instant report delivery

#### **Professional Credibility**
- Industry-standard analysis
- Regulatory compliance
- Professional disclaimers
- Market expertise demonstration

This professional comparison system elevates real estate agents from basic property comparisons to sophisticated investment advisors, providing the analytical tools and professional presentation materials needed to serve high-value clients effectively.
      `
    }
  })

  // Download quote PDF
  .get('/download/:fileName', async ({ params: { fileName } }) => {
    try {
      const filePath = path.join(process.cwd(), 'storage', 'quotes', fileName);

      if (!existsSync(filePath)) {
        return new Response('File not found', { status: 404 });
      }

      const fileStream = createReadStream(filePath);
      
      return new Response(fileStream as any, {
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition': `attachment; filename="${fileName}"`,
          'Cache-Control': 'no-cache'
        }
      });

    } catch (error) {
      console.error('File download error:', error);
      return new Response('Download failed', { status: 500 });
    }
  }, {
    detail: {
      tags: ['Quotes'],
      summary: 'Download Quote PDF',
      description: 'Download a generated quote PDF file'
    }
  })

  // Download comparison PDF
  .get('/download-comparison/:fileName', async ({ params: { fileName } }) => {
    try {
      // Check both old and new comparison directories
      let filePath = path.join(process.cwd(), 'storage', 'professional-comparisons', fileName);
      
      // Fallback to old comparisons directory if file not found
      if (!existsSync(filePath)) {
        filePath = path.join(process.cwd(), 'storage', 'comparisons', fileName);
      }

      if (!existsSync(filePath)) {
        return new Response('File not found', { status: 404 });
      }

      const fileStream = createReadStream(filePath);
      
      return new Response(fileStream as any, {
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition': `attachment; filename="${fileName}"`,
          'Cache-Control': 'no-cache'
        }
      });

    } catch (error) {
      console.error('File download error:', error);
      return new Response('Download failed', { status: 500 });
    }
  }, {
    detail: {
      tags: ['Quotes'],
      summary: 'Download Professional Comparison PDF',
      description: 'Download a generated professional property comparison PDF report'
    }
  })

  // Get quote configuration
  .get('/config', async () => {
    try {
      const { getQuoteConfig } = await import('../services/quote-generator');
      const config = await getQuoteConfig();

      return {
        success: true,
        config: {
          agentCommissionRate: config.agentCommissionRate,
          legalFeesRate: config.legalFeesRate,
          administrativeFees: config.administrativeFees,
          taxRate: config.taxRate,
          validityDays: config.validityDays,
          currency: config.currency,
          language: config.language
        }
      };

    } catch (error) {
      console.error('Config retrieval error:', error);
      return {
        success: false,
        error: 'Failed to retrieve quote configuration'
      };
    }
  }, {
    detail: {
      tags: ['Quotes'],
      summary: 'Get Quote Configuration',
      description: `
## ⚙️ Quote Configuration Management

Retrieve current quote generation configuration including rates, fees, and default settings.

### 📊 Configuration Parameters

- **Agent Commission Rate**: Percentage commission for agents
- **Legal Fees Rate**: Percentage for legal processing
- **Administrative Fees**: Fixed administrative costs (DZD)
- **Tax Rate**: VAT/Tax percentage
- **Validity Days**: Default quote validity period
- **Currency**: Default currency (DZD)
- **Language**: Default language (fr/ar/en)

### 🔧 Settings Management

Configuration is managed through the settings system and can be updated by administrators to reflect:
- Market changes
- Regulatory updates
- Business policy adjustments
- Regional variations
      `
    }
  })

  // Calculate quote preview (without saving)
  .post('/preview', async ({ body }) => {
    try {
      const { propertyId, customConfig } = body;

      // Generate quote preview without saving
      const quote = await generatePropertyQuote(propertyId, undefined, undefined, customConfig);

      return {
        success: true,
        preview: {
          property: quote.property,
          pricing: quote.pricing,
          terms: {
            validUntil: quote.terms.validUntil,
            paymentTerms: quote.terms.paymentTerms
          },
          formattedTotal: formatCurrency(quote.pricing.totalAmount, quote.currency, 'fr')
        }
      };

    } catch (error) {
      console.error('Quote preview error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to generate quote preview'
      };
    }
  }, {
    body: t.Object({
      propertyId: t.String(),
      customConfig: t.Optional(t.Object({
        agentCommissionRate: t.Optional(t.Number()),
        legalFeesRate: t.Optional(t.Number()),
        administrativeFees: t.Optional(t.Number()),
        taxRate: t.Optional(t.Number()),
        validityDays: t.Optional(t.Number())
      }))
    }),
    detail: {
      tags: ['Quotes'],
      summary: 'Preview Quote Calculation',
      description: `
## 👁️ Quote Preview System

Generate quote calculations and pricing breakdowns without creating a formal quote document.

### 🎯 Preview Features

- **Instant Calculations**: Real-time pricing with custom parameters
- **Parameter Testing**: Test different commission rates and fees
- **Visual Breakdown**: Detailed cost itemization
- **Format Preview**: See how totals will appear in different formats

### 💡 Use Cases

#### **Rate Negotiation**
- Test different commission structures
- Compare fee scenarios
- Optimize pricing strategies
- Client consultation support

#### **What-If Analysis**
- Scenario planning
- Sensitivity analysis
- Market positioning
- Competitive analysis

### 📊 Preview Response

Returns calculated pricing without generating formal documents:
- Property information
- Detailed pricing breakdown
- Terms and validity information
- Formatted currency displays
      `
    }
  });

// Export the routes
export default quotesRoutes; 