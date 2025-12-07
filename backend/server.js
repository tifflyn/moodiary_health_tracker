const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'API Proxy Running', version: '1.0.0' });
});

// Example: Weather API proxy
app.post('/api/weather', async (req, res) => {
  try {
    const { city } = req.body;
    
    // Call real API with secret key (from environment)
    const response = await axios.get(
      `https://api.weatherapi.com/v1/current.json`,
      {
        params: {
          q: city,
          key: process.env.WEATHER_API_KEY  // Your key goes here
        }
      }
    );
    
    res.json(response.data);
  } catch (error) {
    console.error('Weather API error:', error.message);
    res.status(500).json({ error: 'Failed to fetch weather data' });
  }
});

// Generic proxy for any API
app.post('/api/proxy', async (req, res) => {
  try {
    const { endpoint, method = 'GET', data, headers = {} } = req.body;
    
    // Add your secret keys based on endpoint
    const apiKey = getApiKeyForEndpoint(endpoint);
    if (apiKey) {
      headers['Authorization'] = `Bearer ${apiKey}`;
    }
    
    const response = await axios({
      method,
      url: endpoint,
      data,
      headers
    });
    
    res.json(response.data);
  } catch (error) {
    console.error('Proxy error:', error.message);
    res.status(500).json({ 
      error: 'Proxy failed',
      details: error.response?.data || error.message 
    });
  }
});

function getApiKeyForEndpoint(endpoint) {
  // Map endpoints to environment variables
  const keyMap = {
    'https://api.stripe.com': process.env.STRIPE_API_KEY,
    'https://maps.googleapis.com': process.env.GOOGLE_MAPS_KEY,
    'https://api.openai.com': process.env.OPENAI_API_KEY,
    // Add more as needed
  };
  
  for (const [url, key] of Object.entries(keyMap)) {
    if (endpoint.includes(url)) return key;
  }
  
  return null;
}

app.listen(PORT, () => {
  console.log(`🚀 API Proxy running on port ${PORT}`);
});