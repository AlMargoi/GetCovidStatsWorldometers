### User configuration area
$Countries = "Romania", "Netherlands", "Germany", "France", "India", "UK", "Italy"
#############################

$AllPossibleCountries = "USA", "India", "Brazil", "France", "Turkey", "Russia", "UK", "Italy", "Germany", "Spain", "Argentina", "Colombia", "Poland", "Iran", "Mexico", "Ukraine", "Peru", "Indonesia", "Czechia", "South Africa", "Netherlands", "Canada", "Chile", "Philippines", "Iraq", "Romania", "Sweden", "Belgium", "Pakistan", "Portugal", "Israel", "Hungary", "Bangladesh", "Jordan", "Japan", "Serbia", "Switzerland", "Austria", "UAE", "Lebanon", "Malaysia", "Nepal", "Morocco", "Saudi Arabia", "Ecuador", "Bulgaria", "Greece", "Slovakia", "Belarus", "Kazakhstan", "Panama", "Croatia", "Bolivia", "Georgia", "Tunisia", "Paraguay", "Azerbaijan", "Palestine", "Costa Rica", "Kuwait", "Dominican Republic", "Denmark", "Lithuania", "Ethiopia", "Uruguay", "Ireland", "Egypt", "Moldova", "Slovenia", "Guatemala", "Honduras", "Venezuela", "Armenia", "Bahrain", "Qatar", "Oman", "Bosnia and Herzegovina", "Libya", "Kenya", "Sri Lanka", "Nigeria", "North Macedonia", "Myanmar", "S. Korea", "Thailand", "Cuba", "Albania", "Latvia", "Estonia", "Algeria", "Norway", "Kyrgyzstan", "Montenegro", "Uzbekistan", "Ghana", "Zambia", "Finland", "China", "Cameroon", "El Salvador", "Cyprus", "Mozambique", "Luxembourg", "Afghanistan", "Singapore", "Maldives", "Mongolia", "Namibia", "Botswana", "Jamaica", "Ivory Coast", "Uganda", "Senegal", "Madagascar", "Zimbabwe", "Sudan", "Malawi", "Angola", "DRC", "Malta", "Australia", "Cabo Verde", "Rwanda", "Cambodia", "Syria", "Gabon", "Réunion", "French Guiana", "Guinea", "Trinidad and Tobago", "Mayotte", "Mauritania", "French Polynesia", "Eswatini", "Guadeloupe", "Guyana", "Papua New Guinea", "Somalia", "Mali", "Haiti", "Andorra", "Burkina Faso", "Togo", "Tajikistan", "Suriname", "Belize", "Curaçao", "Martinique", "Hong Kong", "Djibouti", "Bahamas", "Congo", "Aruba", "Lesotho", "Seychelles", "South Sudan", "Equatorial Guinea", "Benin", "Nicaragua", "CAR", "Yemen", "Iceland", "Gambia", "Timor-Leste", "Vietnam", "Taiwan", "Niger", "San Marino", "Saint Lucia", "Chad", "Burundi", "Gibraltar", "Sierra Leone", "Channel Islands", "Barbados", "Eritrea", "Comoros", "Guinea-Bissau", "Liechtenstein", "New Zealand", "Monaco", "Bermuda", "Turks and Caicos", "Sint Maarten", "Sao Tome and Principe", "Liberia", "St. Vincent Grenadines", "Saint Martin", "Laos", "Caribbean Netherlands", "Isle of Man", "Bhutan", "Mauritius", "Antigua and Barbuda", "St. Barth", "Diamond Princess", "Faeroe Islands", "Cayman Islands", "Tanzania", "Wallis and Futuna", "Fiji", "British Virgin Islands", "Brunei", "Dominica", "Grenada", "New Caledonia", "Anguilla", "Falkland Islands", "Saint Kitts and Nevis", "Macao", "Greenland", "Vatican City", "Saint Pierre Miquelon", "Montserrat", "Solomon Islands", "Western Sahara", "MS Zaandam", "Vanuatu", "Marshall Islands", "Samoa", "Saint Helena", "Micronesia"

$RequestHT = @{
    Uri = "https://www.worldometers.info/coronavirus/"
    Method = "GET"
}
$MainPageData = Invoke-WebRequest @RequestHT
$RawMainPageData = $MainPageData.RawContent -split "`n"

$Trends = @()
$Counter = 0
foreach($Country in $Countries){
    $Counter++
    $percentComplete = ($counter*100/($Countries.Count))
    $percentCompleteString = $percentComplete.ToString("##.#")
    Write-Progress -Activity "Getting data from worldometers - $percentCompleteString %" -PercentComplete $percentComplete

    if(!$AllPossibleCountries.Contains($Country)){
        Write-Host "`"$Country`" is incorrect. It is not in the list of countires provided by Worldometers. Please check again." -ForegroundColor YELLOW
        continue
    }

    $RequestHT = @{
        Uri = "https://www.worldometers.info/coronavirus/country/$($Country)/"
        Method = "GET"
    }

    ($RawMainPageData -match "$($Country)\-population")[0] -replace ",","" -match "[0-9]{6,}" | Out-Null
    [double]$CountryPopulation = $Matches[0]

    $CountryData = Invoke-WebRequest @RequestHT
    $RawCountryData = $CountryData.RawContent -split "`n"

    $InterestIndex = $RawCountryData.IndexOf("            text: 'Daily New Cases'")
    $InterestDeathsIndex = $RawCountryData.IndexOf("            text: 'Daily Deaths'")

    $DatesIndex = $InterestIndex + 8
    $DeathsDatesIndex = $InterestDeathsIndex + 8

    $DailyCasesIndex = $InterestIndex + 48
    $DailyDeathsIndex = $InterestDeathsIndex + 49

    $Dates = $RawCountryData[$DatesIndex] -replace "\s","" -replace "categories:\[","" -replace "\]\},","" -replace "`",`"","|" -replace "`"","" -split "\|"
    $DeathDates = $RawCountryData[$DeathsDatesIndex] -replace "\s","" -replace "categories:\[","" -replace "\]\},","" -replace "`",`"","|" -replace "`"","" -split "\|"
    $DailyCases = $RawCountryData[$DailyCasesIndex] -replace "\s","" -replace "data:\[","" -replace "\]\},","" -replace "`",`"","|" -replace "`"","" -replace "null","0" -split ","
    $DailyDeaths = $RawCountryData[$DailyDeathsIndex] -replace "\s","" -replace "data:\[","" -replace "\]\},","" -replace "`",`"","|" -replace "`"","" -replace "null","0" -split ","
    ######################################
    # Calculate Daily Trends on New Cases#
    ######################################
    $TotalLast14Days = 0
    foreach($Day in $DailyCases[-14..-1]){
        $TotalLast14Days += [double]$Day
    }

    $TotalLast7Days = 0
    foreach($Day in $DailyCases[-7..-1]){
        $TotalLast7Days += [double]$Day
    }

    $TotalLast7DaysPer100K = [double]($TotalLast7Days * 100000 / $CountryPopulation).ToString("##.#")
    $TotalLast7DaysPer1M = [double]($TotalLast7Days * 1000000 / $CountryPopulation).ToString("##.#")
    $TotalLast14DaysPer100K = [double]($TotalLast14Days  * 100000 / $CountryPopulation).ToString("##.#")
    $TotalLast14DaysPer1M =  [double]($TotalLast14Days * 1000000 / $CountryPopulation).ToString("##.#")
    #######################################
    # Calculate Daily Trends on New Deaths#
    #######################################
    $TotalLast14DaysDeaths = 0
    foreach($Day in $DailyDeaths[-14..-1]){
        $TotalLast14DaysDeaths += [double]$Day
    }

    $TotalLast7DaysDeaths = 0
    foreach($Day in $DailyDeaths[-7..-1]){
        $TotalLast7DaysDeaths += [double]$Day
    }

    $DeathsLast7DaysPer100K = [double]($TotalLast7DaysDeaths * 100000 / $CountryPopulation).ToString("##.#")
    $DeathsLast7DaysPer1M = [double]($TotalLast7DaysDeaths * 1000000 / $CountryPopulation).ToString("##.#")
    $DeathsLast14DaysPer100K = [double]($TotalLast14DaysDeaths  * 100000 / $CountryPopulation).ToString("##.#")
    $DeathsLast14DaysPer1M =  [double]($TotalLast14DaysDeaths * 1000000 / $CountryPopulation).ToString("##.#")
    #######################################

    $OutputHT = [ordered]@{
        Country = $Country
        Population = $CountryPopulation 
        Last7 = $TotalLast7Days
        Last7Per100K = $TotalLast7DaysPer100K
        Last7Per1M = $TotalLast7Daysper1M
        Last14 = $TotalLast14Days
        Last14Per100K = $TotalLast14DaysPer100K
        Last14Per1M = $DeathsLast14DaysPer1M
        DeathsLast7 = $TotalLast7DaysDeaths
        DeathsLast7Per100K = $DeathsLast7DaysPer100K
        DeathsLast7Per1M = $DeathsLast7Daysper1M
        DeathsLast14 = $TotalLast14DaysDeaths
        DeathsLast14Per100K = $DeathsLast14DaysPer100K
        DeathsLast14Per1M = $DeathsLast14DaysPer1M

    }
    $OutputObject = New-Object -TypeName PSCustomObject -Property $OutputHT

    $Trends += $OutputObject
}

$Trends | Sort Last7Per1M -Descending | FT -AutoSize
