# 🐳 Puppeteer PDF Generation Fix Guide

## Problem Description

The `/api/quotes/pdf` endpoint was failing with the following error in Linux/Docker environments:

```
Failed to launch the browser process!
/root/.cache/puppeteer/chrome/linux-138.0.7204.157/chrome-linux64/chrome: error while loading shared libraries: libglib-2.0.so.0: cannot open shared object file: No such file or directory
```

This is a common issue when running Puppeteer in headless Linux environments without the necessary system dependencies.

## ✅ Solution Implemented

### 1. Enhanced Puppeteer Configuration

Updated all Puppeteer launch configurations in `src/services/pdf-generator.ts` with comprehensive arguments for Linux environments:

```typescript
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
```

### 2. Updated Dockerfile

Enhanced the Dockerfile to include all necessary system dependencies:

```dockerfile
# Install system dependencies for Puppeteer and other requirements
RUN apt-get update && apt-get install -y \
    libssl1.1 \
    curl \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libgbm1 \
    libxkbcommon0 \
    libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*
```

### 3. HTML Fallback System

Created a robust fallback system (`src/services/pdf-generator-fallback.ts`) that generates print-friendly HTML files when Puppeteer fails:

- **Print-optimized HTML**: CSS media queries for proper PDF printing
- **Multi-language support**: Arabic (RTL), French, and English
- **Professional styling**: Company branding and responsive design
- **Browser-based PDF**: Users can print to PDF using browser's print dialog

### 4. Smart Error Handling

Updated the quotes route to automatically fallback to HTML generation when Puppeteer fails:

```typescript
try {
  const result = await generateQuotePDF(quote, options, companyInfo);
  // Use PDF result
} catch (puppeteerError) {
  console.warn('Puppeteer PDF generation failed, using HTML fallback:', puppeteerError);
  const result = await generateQuoteHTMLFile(quote, options, companyInfo);
  // Use HTML result
}
```

## 🚀 Deployment Instructions

### For Docker Deployment

1. **Rebuild the Docker image** with the updated Dockerfile:
   ```bash
   docker build -t smart-contact-system .
   ```

2. **Run the container** with proper volume mounts:
   ```bash
   docker run -p 3001:3001 \
     -v $(pwd)/storage:/app/storage \
     -v $(pwd)/uploads:/app/uploads \
     --env-file .env \
     smart-contact-system
   ```

### For Linux Server Deployment

1. **Install system dependencies**:
   ```bash
   sudo apt-get update
   sudo apt-get install -y \
     libssl1.1 \
     curl \
     wget \
     gnupg \
     ca-certificates \
     fonts-liberation \
     libasound2 \
     libatk-bridge2.0-0 \
     libatk1.0-0 \
     libatspi2.0-0 \
     libcups2 \
     libdbus-1-3 \
     libdrm2 \
     libgtk-3-0 \
     libnspr4 \
     libnss3 \
     libxcomposite1 \
     libxdamage1 \
     libxrandr2 \
     libxss1 \
     libxtst6 \
     xdg-utils \
     libgbm1 \
     libxkbcommon0 \
     libxshmfence1
   ```

2. **Set environment variables** (optional):
   ```bash
   export CHROME_BIN=/usr/bin/google-chrome-stable
   ```

3. **Start the application**:
   ```bash
   bun run dev
   ```

## 🧪 Testing the Fix

### Test PDF Generation

```bash
curl -X POST http://localhost:3001/api/quotes/pdf \
  -H "Content-Type: application/json" \
  -d '{
    "propertyId": "cmd9e93z9000rmax9hj0a1uyz",
    "contactId": "cmd9h1xtn001t13hmpvjmgwpm",
    "language": "ar",
    "format": "",
    "orientation": "",
    "companyInfo": {
      "name": "",
      "address": "",
      "phone": "",
      "email": "",
      "website": "",
      "taxId": ""
    }
  }'
```

### Expected Response

**Success with PDF**:
```json
{
  "success": true,
  "pdf": {
    "fileName": "quote-QUO-20250719-042778.pdf",
    "downloadUrl": "/api/quotes/download/quote-QUO-20250719-042778.pdf",
    "quote": {
      "quoteNumber": "QUO-20250719-042778",
      "totalAmount": 10245900,
      "currency": "DZD",
      "validUntil": "2025-08-18T07:44:02.778Z"
    }
  }
}
```

**Success with HTML Fallback**:
```json
{
  "success": true,
  "pdf": {
    "fileName": "quote-QUO-20250719-042778.html",
    "downloadUrl": "/uploads/quotes-html/quote-QUO-20250719-042778.html",
    "quote": {
      "quoteNumber": "QUO-20250719-042778",
      "totalAmount": 10245900,
      "currency": "DZD",
      "validUntil": "2025-08-18T07:44:02.778Z"
    }
  }
}
```

## 📁 File Structure

```
system/
├── src/
│   ├── services/
│   │   ├── pdf-generator.ts          # Main PDF generator (Puppeteer)
│   │   └── pdf-generator-fallback.ts # HTML fallback generator
│   └── routes/
│       └── quotes.ts                 # Updated with fallback logic
├── storage/
│   ├── quotes/                       # PDF files
│   └── quotes-html/                  # HTML fallback files
├── uploads/                          # Static file serving
└── Dockerfile                        # Updated with dependencies
```

## 🔧 Configuration Options

### Environment Variables

- `CHROME_BIN`: Path to Chrome executable (optional)
- `NODE_ENV`: Set to 'production' for optimized builds

### PDF Options

- `format`: "A4" or "Letter" (defaults to "A4")
- `orientation`: "portrait" or "landscape" (defaults to "portrait")
- `language`: "ar", "fr", or "en" (defaults to "fr")

## 🎯 Benefits

1. **Reliability**: Automatic fallback ensures quotes are always generated
2. **Performance**: HTML generation is faster than PDF generation
3. **Compatibility**: Works across all environments and platforms
4. **User Experience**: Print-friendly HTML with clear instructions
5. **Maintenance**: Reduced dependency on complex system libraries

## 🚨 Troubleshooting

### If Puppeteer Still Fails

1. **Check system dependencies**:
   ```bash
   ldd /usr/bin/google-chrome-stable
   ```

2. **Verify Chrome installation**:
   ```bash
   google-chrome-stable --version
   ```

3. **Check logs** for specific error messages:
   ```bash
   docker logs <container-id>
   ```

### If HTML Fallback Doesn't Work

1. **Check file permissions**:
   ```bash
   ls -la storage/quotes-html/
   ```

2. **Verify static file serving**:
   ```bash
   curl http://localhost:3001/uploads/quotes-html/test.html
   ```

## 📞 Support

For additional support or questions about the PDF generation system:

- Check the application logs for detailed error messages
- Verify all system dependencies are installed
- Ensure proper file permissions on storage directories
- Test with different browsers and environments

---

**🇩🇿 Algeria Real Estate AI System - Professional PDF Generation Ready!** 