# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the target OU
$targetOU = "OU=Users,OU=Lab-OU,DC=homelab,DC=local"

# Function to generate a random password
function Get-RandomPassword {
    $uppercase = "ABCDEFGHKLMNOPRSTUVWXYZ".ToCharArray()
    $lowercase = "abcdefghiklmnoprstuvwxyz".ToCharArray()
    $number = "0123456789".ToCharArray()
    $special = "!@#$%^&*()_+-=[]{}|;:,.<>?".ToCharArray()

    $password = ($uppercase | Get-Random -Count 2) -join ''
    $password += ($lowercase | Get-Random -Count 2) -join ''
    $password += ($number | Get-Random -Count 2) -join ''
    $password += ($special | Get-Random -Count 2) -join ''
    $password += (($uppercase + $lowercase + $number + $special) | Get-Random -Count 4) -join ''

    return $password
}

# Expanded list of first names and last names for random generation
$firstNames = @(
    "John", "Jane", "Michael", "Emily", "David", "Sarah", "Robert", "Lisa", "William", "Mary",
    "James", "Jennifer", "Richard", "Elizabeth", "Thomas", "Linda", "Charles", "Barbara", "Joseph", "Patricia",
    "Christopher", "Margaret", "Daniel", "Susan", "Paul", "Dorothy", "Mark", "Karen", "Donald", "Nancy",
    "George", "Betty", "Kenneth", "Helen", "Steven", "Sandra", "Edward", "Donna", "Brian", "Carol",
    "Ronald", "Ruth", "Anthony", "Sharon", "Kevin", "Michelle", "Jason", "Laura", "Jeffrey", "Sarah"
)

$lastNames = @(
    "Smith", "Johnson", "Brown", "Taylor", "Anderson", "Wilson", "Miller", "Davis", "Moore", "Jackson",
    "Thompson", "White", "Harris", "Martin", "Garcia", "Martinez", "Robinson", "Clark", "Rodriguez", "Lewis",
    "Lee", "Walker", "Hall", "Allen", "Young", "King", "Wright", "Scott", "Green", "Baker",
    "Adams", "Nelson", "Carter", "Mitchell", "Perez", "Roberts", "Turner", "Phillips", "Campbell", "Parker",
    "Evans", "Edwards", "Collins", "Stewart", "Morris", "Rogers", "Reed", "Cook", "Morgan", "Bell"
)

# Lists for random attribute generation
$offices = @("New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose")
$departments = @("HR", "IT", "Finance", "Marketing", "Sales", "Operations", "R&D", "Customer Service", "Legal", "Engineering")
$jobTitles = @("Manager", "Associate", "Specialist", "Coordinator", "Analyst", "Director", "Assistant", "Supervisor", "Executive", "Representative")

# Create 20 random users
$users = @()
for ($i = 1; $i -le 20; $i++) {
    $firstName = $firstNames | Get-Random
    $lastName = $lastNames | Get-Random
    $username = "$($firstName.ToLower()).$($lastName.ToLower())$i"
    $email = "$username@homelab.local"
    $password = Get-RandomPassword
    
    # Generate random attributes
    $displayName = "$firstName $lastName"
    $office = $offices | Get-Random
    $telephoneNumber = "({0:D3}) {1:D3}-{2:D4}" -f (Get-Random -Minimum 100 -Maximum 999), (Get-Random -Minimum 100 -Maximum 999), (Get-Random -Minimum 1000 -Maximum 9999)
    $company = "ConstCo Inc."
    $department = $departments | Get-Random
    $jobTitle = $jobTitles | Get-Random

    $user = New-ADUser -Name $displayName `
                       -GivenName $firstName `
                       -Surname $lastName `
                       -SamAccountName $username `
                       -UserPrincipalName $email `
                       -EmailAddress $email `
                       -DisplayName $displayName `
                       -Office $office `
                       -OfficePhone $telephoneNumber `
                       -Company $company `
                       -Department $department `
                       -Title $jobTitle `
                       -Enabled $true `
                       -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
                       -Path $targetOU `
                       -PassThru

    $users += $user
    Write-Host "Created user: $username in $targetOU"
    Write-Host "  Display Name: $displayName"
    Write-Host "  Office: $office"
    Write-Host "  Phone: $telephoneNumber"
    Write-Host "  Department: $department"
    Write-Host "  Job Title: $jobTitle"
}

# Get all the AD groups we created earlier (assuming they all start with "ConstCo-")
$adGroups = Get-ADGroup -Filter 'Name -like "ConstCo-*"'

# Assign users to random groups
foreach ($user in $users) {
    $groupsToAssign = $adGroups | Get-Random -Count (Get-Random -Minimum 1 -Maximum 5)
    foreach ($group in $groupsToAssign) {
        Add-ADGroupMember -Identity $group -Members $user
        Write-Host "Added $($user.SamAccountName) to group $($group.Name)"
    }
}

Write-Host "20 random users created in $targetOU with additional attributes and assigned to groups."