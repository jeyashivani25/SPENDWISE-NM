# test-spendwise.ps1
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "    SPENDWISE API TESTER" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$apiUrl = "http://localhost:5001"
Write-Host "API URL: $apiUrl" -ForegroundColor Yellow

# Test 1: Check if server is running
Write-Host "`n[1] Checking server connection..." -ForegroundColor Green
try {
    $response = Invoke-RestMethod -Uri "$apiUrl/" -Method Get -ErrorAction Stop
    Write-Host "✅ Server is running: $($response.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot connect to server!" -ForegroundColor Red
    Write-Host "   Make sure server is running with: node server.js" -ForegroundColor Yellow
    exit
}

# Test 2: Register a new user
Write-Host "`n[2] Registering new user..." -ForegroundColor Green
$registerBody = @{
    name = "Test User"
    email = "test@email.com"
    password = "123456"
}

$registerJson = $registerBody | ConvertTo-Json

try {
    $register = Invoke-RestMethod -Uri "$apiUrl/api/auth/register" `
        -Method Post `
        -Headers @{"Content-Type"="application/json"} `
        -Body $registerJson `
        -ErrorAction Stop
    
    Write-Host "✅ Registration successful!" -ForegroundColor Green
    Write-Host "   User: $($register.name)" -ForegroundColor Green
    Write-Host "   Email: $($register.email)" -ForegroundColor Green
    $token = $register.token
} catch {
    Write-Host "⚠️ Registration failed, trying login..." -ForegroundColor Yellow
    
    # Test 3: Login instead
    Write-Host "`n[3] Logging in..." -ForegroundColor Green
    $loginBody = @{
        email = "test@email.com"
        password = "123456"
    }
    
    $loginJson = $loginBody | ConvertTo-Json
    
    try {
        $login = Invoke-RestMethod -Uri "$apiUrl/api/auth/login" `
            -Method Post `
            -Headers @{"Content-Type"="application/json"} `
            -Body $loginJson `
            -ErrorAction Stop
        
        Write-Host "✅ Login successful!" -ForegroundColor Green
        Write-Host "   User: $($login.name)" -ForegroundColor Green
        Write-Host "   Email: $($login.email)" -ForegroundColor Green
        $token = $login.token
    } catch {
        Write-Host "❌ Login failed!" -ForegroundColor Red
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Error: $responseBody" -ForegroundColor Red
        }
        exit
    }
}

# If we have a token, test protected routes
if ($token) {
    Write-Host "`n✅ Token received successfully!" -ForegroundColor Green
    Write-Host "   Token: $($token.Substring(0, [Math]::Min(20, $token.Length)))..." -ForegroundColor Gray
    
    # Test 4: Get user profile
    Write-Host "`n[4] Getting user profile..." -ForegroundColor Green
    try {
        $profile = Invoke-RestMethod -Uri "$apiUrl/api/auth/profile" `
            -Method Get `
            -Headers @{"Authorization" = "Bearer $token"} `
            -ErrorAction Stop
        
        Write-Host "✅ Profile retrieved!" -ForegroundColor Green
        Write-Host "   Name: $($profile.name)" -ForegroundColor Green
        Write-Host "   Email: $($profile.email)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to get profile!" -ForegroundColor Red
    }
    
    # Test 5: Create a transaction
    Write-Host "`n[5] Creating test transaction..." -ForegroundColor Green
    $transactionBody = @{
        title = "Test Expense"
        amount = 49.99
        type = "expense"
        category = "Food"
        description = "Test transaction"
    }
    
    $transactionJson = $transactionBody | ConvertTo-Json
    
    try {
        $transaction = Invoke-RestMethod -Uri "$apiUrl/api/transactions" `
            -Method Post `
            -Headers @{
                "Content-Type"="application/json"
                "Authorization" = "Bearer $token"
            } `
            -Body $transactionJson `
            -ErrorAction Stop
        
        Write-Host "✅ Transaction created!" -ForegroundColor Green
        Write-Host "   Title: $($transaction.title)" -ForegroundColor Green
        Write-Host "   Amount: $$($transaction.amount)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to create transaction!" -ForegroundColor Red
    }
    
    # Test 6: Get all transactions
    Write-Host "`n[6] Getting all transactions..." -ForegroundColor Green
    try {
        $transactions = Invoke-RestMethod -Uri "$apiUrl/api/transactions" `
            -Method Get `
            -Headers @{"Authorization" = "Bearer $token"} `
            -ErrorAction Stop
        
        Write-Host "✅ Retrieved $($transactions.Count) transactions" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to get transactions!" -ForegroundColor Red
    }
}

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "    TEST COMPLETE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan