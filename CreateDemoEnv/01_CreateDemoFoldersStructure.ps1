# ------------------------------------------------------------------------------
# Author: Ilya Fedotov
# Date: 20.08.2024
# Description: This script creates a structured folder hierarchy for a construction 
#              company, organized into departments, subdepartments, and third-level 
#              categories. The folder structure is generated under a specified base 
#              path, allowing for organized storage of departmental files.
# ------------------------------------------------------------------------------

# Set the base path
$basePath = "C:\Shared\Construction Company"

# Define the department structure with three levels
$departments = @{
    "Administration" = @{
        "Human Resources" = @("Recruitment", "Employee Relations", "Payroll")
        "Finance" = @("Accounting", "Budgeting", "Financial Planning")
        "Legal" = @("Contracts", "Compliance", "Dispute Resolution")
    }
    "Operations" = @{
        "Project Management" = @("Scheduling", "Resource Allocation", "Risk Management")
        "Site Supervision" = @("Daily Reports", "Subcontractor Coordination", "Safety Inspections")
        "Quality Control" = @("Inspections", "Testing", "Documentation")
    }
    "Engineering" = @{
        "Structural" = @("Steel", "Concrete", "Timber")
        "Civil" = @("Earthwork", "Drainage", "Roads")
        "Mechanical" = @("HVAC", "Plumbing", "Fire Protection")
        "Electrical" = @("Power Systems", "Lighting", "Low Voltage")
    }
    "Procurement" = @{
        "Vendor Management" = @("Supplier Database", "Performance Evaluation", "Contract Negotiation")
        "Materials" = @("Ordering", "Inventory", "Quality Assurance")
        "Equipment" = @("Rentals", "Maintenance", "Asset Tracking")
    }
    "Marketing" = @{
        "Business Development" = @("Market Research", "Proposal Writing", "Presentations")
        "Client Relations" = @("Customer Service", "Feedback Management", "Client Retention")
    }
    "Safety" = @{
        "Training" = @("New Employee Orientation", "Ongoing Education", "Certification Programs")
        "Compliance" = @("Regulations", "Audits", "Reporting")
        "Incident Response" = @("Emergency Procedures", "Investigation", "Corrective Actions")
    }
}

# Create the base directory
New-Item -Path $basePath -ItemType Directory -Force

# Create departments, subdepartments, and third-level folders
foreach ($dept in $departments.Keys) {
    $deptPath = Join-Path $basePath $dept
    New-Item -Path $deptPath -ItemType Directory -Force
    
    foreach ($subdept in $departments[$dept].Keys) {
        $subdeptPath = Join-Path $deptPath $subdept
        New-Item -Path $subdeptPath -ItemType Directory -Force
        
        foreach ($thirdLevel in $departments[$dept][$subdept]) {
            $thirdLevelPath = Join-Path $subdeptPath $thirdLevel
            New-Item -Path $thirdLevelPath -ItemType Directory -Force
        }
    }
}

Write-Host "Folder structure with three levels created successfully in $basePath"
