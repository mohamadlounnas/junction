#!/usr/bin/env bun

/**
 * Admin Settings Test Script
 * Tests all admin settings functionality with Laravel-style API
 */

const BASE_URL = 'http://localhost:3001';
const AGENT_ID = 'cmd84e3dd000442gml0eql3fk'; // Agent 5

interface TestResult {
  test: string;
  success: boolean;
  message: string;
  data?: any;
}

async function makeRequest(url: string, options: RequestInit = {}): Promise<any> {
  const response = await fetch(url, {
    headers: {
      'Authorization': `Bearer ${AGENT_ID}`,
      'Content-Type': 'application/json',
      ...options.headers
    },
    ...options
  });
  
  return response.json();
}

async function runTests(): Promise<void> {
  const results: TestResult[] = [];
  
  console.log('🧪 Testing Admin Settings API...\n');
  
  // Test 1: Get all settings
  try {
    const response = await makeRequest(`${BASE_URL}/api/admin/settings`);
    results.push({
      test: 'Get All Settings',
      success: response.success,
      message: response.message,
      data: response.data
    });
    console.log('✅ Get All Settings:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Get All Settings',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Get All Settings: FAILED');
  }
  
  // Test 2: Get settings by category
  try {
    const response = await makeRequest(`${BASE_URL}/api/admin/settings/category/algorithm`);
    results.push({
      test: 'Get Settings by Category',
      success: response.success,
      message: response.message,
      data: response.data
    });
    console.log('✅ Get Settings by Category:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Get Settings by Category',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Get Settings by Category: FAILED');
  }
  
  // Test 3: Update algorithm setting
  try {
    const response = await makeRequest(`${BASE_URL}/api/admin/settings/learning_rate`, {
      method: 'PUT',
      body: JSON.stringify({ value: 0.15 })
    });
    results.push({
      test: 'Update Algorithm Setting',
      success: response.success,
      message: response.message,
      data: response.data
    });
    console.log('✅ Update Algorithm Setting:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Update Algorithm Setting',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Update Algorithm Setting: FAILED');
  }
  
  // Test 4: Update vector weights
  try {
    const newWeights = {
      price: 0.30,
      area: 0.25,
      location: 0.20,
      property_type: 0.10,
      furnishing: 0.08,
      condition: 0.05,
      rooms: 0.02
    };
    
    const response = await makeRequest(`${BASE_URL}/api/admin/settings/vector_weights`, {
      method: 'PUT',
      body: JSON.stringify({ value: newWeights })
    });
    results.push({
      test: 'Update Vector Weights',
      success: response.success,
      message: response.message,
      data: response.data
    });
    console.log('✅ Update Vector Weights:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Update Vector Weights',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Update Vector Weights: FAILED');
  }
  
  // Test 5: Create new setting
  try {
    const response = await makeRequest(`${BASE_URL}/api/admin/settings`, {
      method: 'POST',
      body: JSON.stringify({
        key: 'custom_setting',
        value: 'test_value',
        type: 'STRING',
        category: 'system',
        description: 'Test custom setting'
      })
    });
    results.push({
      test: 'Create New Setting',
      success: response.success,
      message: response.message,
      data: response.data
    });
    console.log('✅ Create New Setting:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Create New Setting',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Create New Setting: FAILED');
  }
  
  // Test 6: Bulk update settings
  try {
    const bulkSettings = [
      {
        key: 'max_recommendations',
        value: 75,
        type: 'NUMBER',
        category: 'algorithm'
      },
      {
        key: 'recommendation_threshold',
        value: 0.4,
        type: 'NUMBER',
        category: 'algorithm'
      }
    ];
    
    const response = await makeRequest(`${BASE_URL}/api/admin/settings/bulk`, {
      method: 'POST',
      body: JSON.stringify({ settings: bulkSettings })
    });
    results.push({
      test: 'Bulk Update Settings',
      success: response.success,
      message: response.message,
      data: response.data
    });
    console.log('✅ Bulk Update Settings:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Bulk Update Settings',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Bulk Update Settings: FAILED');
  }
  
  // Test 7: Clear cache
  try {
    const response = await makeRequest(`${BASE_URL}/api/admin/settings/clear-cache`, {
      method: 'POST'
    });
    results.push({
      test: 'Clear Cache',
      success: response.success,
      message: response.message
    });
    console.log('✅ Clear Cache:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Clear Cache',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Clear Cache: FAILED');
  }
  
  // Test 8: Delete custom setting
  try {
    const response = await makeRequest(`${BASE_URL}/api/admin/settings/custom_setting`, {
      method: 'DELETE'
    });
    results.push({
      test: 'Delete Setting',
      success: response.success,
      message: response.message
    });
    console.log('✅ Delete Setting:', response.success ? 'PASSED' : 'FAILED');
  } catch (error) {
    results.push({
      test: 'Delete Setting',
      success: false,
      message: error instanceof Error ? error.message : 'Unknown error'
    });
    console.log('❌ Delete Setting: FAILED');
  }
  
  // Print summary
  console.log('\n📊 Test Results Summary:');
  console.log('========================');
  
  const passed = results.filter(r => r.success).length;
  const total = results.length;
  
  results.forEach(result => {
    const status = result.success ? '✅' : '❌';
    console.log(`${status} ${result.test}: ${result.success ? 'PASSED' : 'FAILED'}`);
    if (!result.success) {
      console.log(`   Error: ${result.message}`);
    }
  });
  
  console.log(`\n🎯 Overall: ${passed}/${total} tests passed (${Math.round(passed/total*100)}%)`);
  
  if (passed === total) {
    console.log('🎉 All admin settings tests passed!');
  } else {
    console.log('⚠️ Some tests failed. Check the errors above.');
  }
}

// Run the tests
runTests().catch(console.error); 