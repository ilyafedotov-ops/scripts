param (
    [int]$NumberOfUsers = 10 # Default number of users to create
)

function Generate-ComplexPassword {

    $passwordLength = 12
    $passwordChars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@$?_"
    $random = new-object System.Random
    $newPassword = for($i=0; $i -lt $passwordLength; $i++) {
        $passwordChars[$random.Next(0,$passwordChars.Length)]
    }
    return -join $newPassword
}

Import-Module ActiveDirectory

# File paths for CSV and log
$csvFilePath = "C:\Path\To\Your\Output\users.csv"
$logFilePath = "C:\Path\To\Your\Output\log.txt"

# Header for CSV file
"username,password" | Out-File -FilePath $csvFilePath -Encoding UTF8

for ($i = 1; $i -le $NumberOfUsers; $i++) {

    $username = "User$i"
    $password = Generate-ComplexPassword
    $userDetails = @{
        SamAccountName = $username
        UserPrincipalName = "$username@yourdomain.com"
        Name = $username
        Enabled = $true
        ChangePasswordAtLogon = $false
        AccountPassword = (ConvertTo-SecureString -AsPlainText $password -Force)
        Path = "OU=Users,DC=yourdomain,DC=com" # Change this to your desired OU
    }

    try {

        New-ADUser @userDetails
        "$username,$password" | Out-File -FilePath $csvFilePath -Append -Encoding UTF8
        "Successfully created user: $username" | Out-File -FilePath $logFilePath -Append -Encoding UTF8
    } catch {
        "Error creating user: $username. Error: $_" | Out-File -FilePath $logFilePath -Append -Encoding UTF8
    }

}