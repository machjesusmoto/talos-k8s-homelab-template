# Grocy - Smart Household Management

Expand your home automation beyond media into comprehensive household management with Grocy - your personal ERP system for the home!

## Overview

**Grocy** is a web-based self-hosted groceries & household management solution for your home. It's like having a personal assistant for managing your entire household inventory, meal planning, and daily tasks.

- **URL**: https://grocy.k8s.dttesting.com
- **Default Login**: No authentication by default (configure after first access)
- **Official Site**: https://grocy.info

## Core Features

### 🛒 **Inventory Management**
- **Stock tracking** for groceries, household items, and consumables
- **Barcode scanning** for easy product entry and consumption
- **Expiration date tracking** with alerts and notifications
- **Shopping list generation** based on stock levels and meal plans
- **Waste tracking** to optimize purchasing decisions

### 🍳 **Meal Planning & Recipes**
- **Recipe management** with ingredients, instructions, and photos
- **Meal planning calendar** with automatic shopping list generation
- **Nutrition tracking** with calorie and macro calculations
- **Recipe scaling** for different serving sizes
- **Favorite recipes** and rating system

### 📋 **Task & Chore Management**
- **Recurring tasks** with customizable schedules
- **Chore assignments** for household members
- **Task tracking** with completion history
- **Maintenance schedules** for appliances and equipment
- **Calendar integration** for all household activities

### 💰 **Expense Tracking**
- **Shopping expense tracking** with receipt scanning
- **Budget management** by category
- **Price tracking** for products over time
- **Cost analysis** and spending patterns
- **Multi-store price comparison**

### 📊 **Analytics & Insights**
- **Consumption patterns** and usage statistics
- **Waste analysis** to reduce food waste
- **Shopping trends** and optimization suggestions
- **Nutrition analysis** and dietary tracking
- **Household efficiency metrics**

## Initial Setup

### First-Time Configuration
1. **Access Grocy**: https://grocy.k8s.dttesting.com
2. **Basic Setup**: Configure your preferences in Settings
3. **User Management**: Set up authentication and user accounts
4. **Product Database**: Add your commonly used products
5. **Locations**: Define storage locations (pantry, fridge, freezer)

### Essential Configuration

#### User Settings
```
Settings → User Settings
- Default page after login
- Language and locale (en_US configured)
- Currency (USD configured)
- Energy unit (kcal configured)
- Date/time format preferences
```

#### Stock Settings
```
Settings → Stock Settings
- Default best before days for product types
- Auto-decimal amounts for fractional products
- Default locations for different product categories
- Barcode lookup configuration
```

#### Shopping Settings
```
Settings → Shopping Settings
- Default shopping location
- Auto-add to shopping list thresholds
- Shopping list grouping preferences
- Receipt scanning configuration
```

## Product Management

### Adding Products
1. **Stock → Products → Add Product**
2. **Basic Information**:
   - Product name and description
   - Barcode (scan or enter manually)
   - Product group (dairy, produce, pantry, etc.)
   - Default location and quantity unit

3. **Stock Information**:
   - Minimum stock level (triggers shopping list)
   - Default best before days
   - Factor for unit conversions
   - Enable tare weight for bulk items

### Barcode Scanning
- **Mobile Access**: Use your phone to scan barcodes
- **API Integration**: Connect to OpenFoodFacts for automatic product data
- **Custom Barcodes**: Create internal barcodes for bulk items
- **Batch Operations**: Add multiple items quickly

### Location Management
```
Stock → Locations
- Fridge (temperature controlled)
- Freezer (frozen storage)
- Pantry (dry goods)
- Cleaning Supplies
- Bathroom
- Kitchen Counters
```

## Shopping List Automation

### Automatic Generation
- **Stock Level Triggers**: Items below minimum stock automatically added
- **Meal Plan Integration**: Recipe ingredients added for planned meals
- **Recurring Items**: Regular purchases on schedule
- **Seasonal Adjustments**: Quantity adjustments based on usage patterns

### Shopping Workflow
1. **Review List**: Check generated shopping list
2. **Optimize Route**: Group by store sections/locations
3. **Mobile Shopping**: Use mobile interface while shopping
4. **Quick Consume**: Mark items as purchased and consumed
5. **Receipt Tracking**: Photo receipts for expense tracking

### Store Integration
- **Multiple Stores**: Track prices across different stores
- **Store Sections**: Organize shopping list by store layout
- **Price History**: Track price changes over time
- **Best Deals**: Identify best stores for specific items

## Recipe & Meal Planning

### Recipe Creation
```
Recipes → Add Recipe
- Recipe name and description
- Servings and preparation time
- Ingredients with quantities
- Step-by-step instructions
- Photos and tips
- Nutrition information
```

### Meal Planning Calendar
1. **Plan Meals**: Drag recipes to calendar days
2. **Automatic Shopping**: Ingredients added to shopping list
3. **Batch Cooking**: Plan for meal prep sessions
4. **Dietary Restrictions**: Filter recipes by dietary needs
5. **Leftover Management**: Track and plan leftover usage

### Recipe Features
- **Recipe Scaling**: Automatically adjust for serving size
- **Ingredient Substitutions**: Track alternative ingredients
- **Cooking Notes**: Personal modifications and tips
- **Rating System**: Rate and favorite recipes
- **Recipe Sharing**: Export/import recipe collections

## Task & Chore Management

### Recurring Tasks
```
Tasks → Tasks → Add Task
- Task name and description
- Recurrence pattern (daily, weekly, monthly)
- Assignment to household members
- Due date calculation
- Completion tracking
```

### Household Maintenance
- **Appliance Maintenance**: Filter changes, cleaning schedules
- **Home Maintenance**: Seasonal tasks, inspections
- **Garden/Lawn Care**: Watering, fertilizing, mowing
- **Vehicle Maintenance**: Oil changes, inspections
- **Pet Care**: Vet appointments, medication schedules

### Task Categories
- **Daily**: Dishes, bed making, tidying
- **Weekly**: Laundry, vacuuming, grocery shopping
- **Monthly**: Deep cleaning, bill review, maintenance
- **Seasonal**: HVAC service, gutter cleaning, winterizing
- **Annual**: Insurance review, tax preparation, major repairs

## Mobile Access & Apps

### Mobile Web Interface
- **Responsive Design**: Full functionality on mobile devices
- **Barcode Scanning**: Built-in camera scanning
- **Quick Actions**: Fast consume, add to shopping list
- **Offline Capability**: Basic functionality without internet

### Third-Party Apps
- **Grocy Mobile** (Android): Native mobile application
- **Pantry Party** (iOS): Third-party iOS client
- **API Access**: Build custom integrations
- **Home Assistant**: Integration with smart home systems

## API & Integrations

### REST API
```bash
# Get all products
curl -H "GROCY-API-KEY: your-api-key" \
  https://grocy.k8s.dttesting.com/api/objects/products

# Add stock
curl -X POST -H "GROCY-API-KEY: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"amount": 2, "best_before_date": "2024-07-01"}' \
  https://grocy.k8s.dttesting.com/api/stock/products/1/add

# Consume stock
curl -X POST -H "GROCY-API-KEY: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"amount": 1}' \
  https://grocy.k8s.dttesting.com/api/stock/products/1/consume
```

### Home Assistant Integration
```yaml
# configuration.yaml
grocy:
  url: https://grocy.k8s.dttesting.com
  api_key: your-grocy-api-key
  verify_ssl: true

# Automations
- alias: "Low Stock Alert"
  trigger:
    platform: numeric_state
    entity_id: sensor.grocy_stock_milk
    below: 1
  action:
    service: notify.mobile_app
    data:
      message: "Milk is running low!"
```

### Shopping List Apps
- **Bring!**: Sync with Bring! shopping list app
- **Any.do**: Export shopping lists
- **Google Keep**: Integration via API
- **OurGroceries**: Family sharing integration

## Advanced Features

### Batch Operations
- **Bulk Stock Entry**: Add multiple items at once
- **Mass Consumption**: Consume multiple items together
- **Batch Expiration**: Handle multiple expiring items
- **Import/Export**: Backup and transfer data

### Custom Fields
- **Product Attributes**: Add custom product properties
- **User Fields**: Track personal preferences
- **Location Properties**: Custom location attributes
- **Recipe Metadata**: Additional recipe information

### Reporting & Analytics
```
Stock Reports:
- Current stock levels
- Expiring items
- Missing items (below minimum stock)
- Waste tracking
- Price analysis

Usage Reports:
- Consumption patterns
- Shopping frequency
- Recipe popularity
- Task completion rates
```

## Data Management

### Backup & Export
```bash
# Backup Grocy data
kubectl exec -n household deployment/grocy -- \
  tar -czf - /config > grocy-backup.tar.gz

# Export database
kubectl exec -n household deployment/grocy -- \
  sqlite3 /config/data/grocy.db .dump > grocy-database.sql

# Export specific data
curl -H "GROCY-API-KEY: your-key" \
  https://grocy.k8s.dttesting.com/api/objects/products > products.json
```

### Data Import
- **CSV Import**: Bulk import products, recipes, tasks
- **Barcode Database**: Import from OpenFoodFacts
- **Recipe Import**: Import from popular recipe sites
- **Migration Tools**: Transfer from other household apps

## Security & Privacy

### Authentication Setup
1. **Enable Authentication**: Settings → User Management
2. **Create Admin User**: Set username and strong password
3. **User Permissions**: Configure role-based access
4. **API Security**: Generate secure API keys
5. **Session Management**: Configure timeout settings

### Privacy Features
- **Local Hosting**: All data stays on your infrastructure
- **No Cloud Sync**: Complete control over your data
- **Encrypted Storage**: Database encryption options
- **Access Logs**: Track user activity
- **Secure API**: API key authentication

## Household Automation Ideas

### Smart Home Integration
- **Low Stock Alerts**: Automatic notifications when items run low
- **Shopping Reminders**: Location-based shopping list notifications
- **Meal Planning**: Calendar integration with smart displays
- **Expiration Alerts**: Smart speaker announcements
- **Inventory Updates**: Automatic updates via smart scales

### Family Coordination
- **Shared Shopping Lists**: Real-time family shopping coordination
- **Chore Assignments**: Automatic task distribution
- **Meal Voting**: Family input on meal planning
- **Allowance Tracking**: Link chores to allowance payments
- **Calendar Sync**: Integrate with family calendars

### Optimization Workflows
- **Price Tracking**: Monitor prices across stores
- **Waste Reduction**: Track and minimize food waste
- **Bulk Buying**: Optimize bulk purchase timing
- **Seasonal Planning**: Adjust inventory for seasons
- **Health Tracking**: Monitor nutrition and dietary goals

## Troubleshooting

### Common Issues
```bash
# Check Grocy logs
kubectl logs -n household deployment/grocy -f

# Verify database connectivity
kubectl exec -n household deployment/grocy -- \
  sqlite3 /config/data/grocy.db ".tables"

# Test web interface
curl -s https://grocy.k8s.dttesting.com/api/system/info

# Check file permissions
kubectl exec -n household deployment/grocy -- \
  ls -la /config/data/
```

### Performance Optimization
- **Database Maintenance**: Regular SQLite maintenance
- **Image Optimization**: Compress recipe and product images
- **Cache Configuration**: Optimize PHP caching
- **Mobile Performance**: Optimize for mobile devices

Grocy transforms your homelab from a media powerhouse into a complete life management system, bringing the same level of automation and intelligence to your household that you've achieved with your entertainment stack!