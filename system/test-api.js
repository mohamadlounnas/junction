import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function testAPI() {
  try {
    // Get a property ID and contact ID
    const property = await prisma.property.findFirst();
    const contact = await prisma.contact.findFirst();
    
    console.log('Testing with Property ID:', property?.id);
    console.log('Testing with Contact ID:', contact?.id);
    
    if (property && contact) {
      // Test property-to-contact recommendations API
      const response = await fetch(`http://localhost:3001/api/recommendations/property/${property.id}`);
      const data = await response.json();
      
      console.log('\n🏠 Property → Contact Recommendations API Test:');
      console.log('Status:', response.status);
      console.log('Success:', data.success);
      
      if (data.success) {
        console.log('Property:', data.property?.title);
        console.log('Recommendations found:', data.recommendations?.length || 0);
        if (data.recommendations?.[0]) {
          console.log('Top recommendation:', data.recommendations[0].contact?.name);
          console.log('Match score:', data.recommendations[0].similarity);
        }
      } else {
        console.log('Error:', data.error);
      }
      
      // Test contact-to-property recommendations API  
      const contactResponse = await fetch(`http://localhost:3001/api/recommendations/contact/${contact.id}`);
      const contactData = await contactResponse.json();
      
      console.log('\n👤 Contact → Property Recommendations API Test:');
      console.log('Status:', contactResponse.status);
      console.log('Success:', contactData.success);
      
      if (contactData.success) {
        console.log('Contact:', contactData.contact?.name);
        console.log('Recommendations found:', contactData.recommendations?.length || 0);
        if (contactData.recommendations?.[0]) {
          console.log('Top recommendation:', contactData.recommendations[0].property?.title);
          console.log('Match score:', contactData.recommendations[0].similarity);
        }
      } else {
        console.log('Error:', contactData.error);
      }
      
      // Test collaborative learning API
      console.log('\n🧠 Testing Collaborative Learning API:');
      const learningResponse = await fetch('http://localhost:3001/api/recommendations/learn', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode: 'stats' })
      });
      
      const learningData = await learningResponse.json();
      console.log('Learning API Status:', learningResponse.status);
      console.log('Learning API Success:', learningData.success);
      
      if (learningData.success) {
        console.log('Total Sales:', learningData.data.totalSales);
        console.log('Total Users:', learningData.data.totalUsers);
        console.log('Average Success Score:', (learningData.data.averageSuccessScore * 100).toFixed(1) + '%');
        console.log('Collaborative Learning Enabled:', learningData.data.config.enableCollaborativeLearning);
      } else {
        console.log('Learning Error:', learningData.error);
      }
    }
    
    console.log('\n✅ API Testing Complete!');
    
  } catch (error) {
    console.error('Test failed:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testAPI(); 