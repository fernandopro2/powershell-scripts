﻿param(
    [string[]]$ServiceTag
)

foreach($St in $ServiceTag){

    $ServiceTagUri = "https://www.dell.com/support/home/en-ca/product-support/servicetag/$St/overview"
 
    $Headers = @{
      "authority"="www.dell.com"
      "method"="GET"
      "scheme"="https"
      "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
      "accept-encoding"="gzip, deflate, br, zstd"
      "accept-language"="fr"
      "cache-control"="no-cache"
      "dnt"="1"
      "dpr"="1"
      "pragma"="no-cache"
      "priority"="u=0, i"
      "sec-ch-dpr"="1"
      "sec-ch-ua"="`"Microsoft Edge`";v=`"129`", `"Not=A?Brand`";v=`"8`", `"Chromium`";v=`"129`""
      "sec-ch-ua-mobile"="?0"
      "sec-ch-ua-platform"="`"Windows`""
      "sec-ch-viewport-width"="1912"
      "sec-fetch-dest"="document"
      "sec-fetch-mode"="navigate"
      "sec-fetch-site"="same-origin"
      "upgrade-insecure-requests"="1"
      "viewport-width"="1912"
    };

    $WebRequestParams = @{
        Uri = $ServiceTagUri
        UserAgent = $UserAgent
        Headers = $Headers
    }  
 
    $WebRequest = $null
    $WebRequest = Invoke-WebRequest @WebRequestParams | select -ExpandProperty rawcontent
    if($WebRequest){
 
        $ServiceEncryptedkey = $WebRequest -split "`n" | Select-String "var serviceEncryptedkey"
        if($ServiceEncryptedkey -match "var serviceEncryptedkey = '(.+)'"){
            $AssetId = $Matches[1]
        }
        $Matches =  $null
        $PlatformCodeName = $WebRequest -split "`n" | Select-String "var PlatformCode"
        if($PlatformCodeName -match "var PlatformCode = '(.+)', PlatformTag\s\s*"){
            $Model = $Matches[1].ToUpper()
        }
 
 
        $AssetReq = Invoke-WebRequest -UseBasicParsing -Uri "https://www.dell.com/support/contractservices/en-ca/entitlement/inline" `
        -Method "POST" `
        -WebSession $session `
        -Headers @{
        "authority"="www.dell.com"
          "method"="POST"
          "path"="/support/contractservices/en-ca/entitlement/inline"
          "scheme"="https"
          "accept"="*/*"
          "accept-encoding"="gzip, deflate, br, zstd"
          "accept-language"="fr"
          "cache-control"="no-cache"
          "dnt"="1"
          "origin"="https://www.dell.com"
          "pragma"="no-cache"
          "priority"="u=1, i"
          "referer"="https://www.dell.com/support/home/en-ca/product-support/servicetag/BSNZLN2/overview"
          "sec-ch-ua"="`"Microsoft Edge`";v=`"129`", `"Not=A?Brand`";v=`"8`", `"Chromium`";v=`"129`""
          "sec-ch-ua-mobile"="?0"
          "sec-ch-ua-platform"="`"Windows`""
          "sec-fetch-dest"="empty"
          "sec-fetch-mode"="cors"
          "sec-fetch-site"="same-origin"
          "x-requested-with"="XMLHttpRequest"
        } `
        -ContentType "application/json" `
        -Body "{`"assetFormat`":`"servicetag`",`"assetId`":`"$AssetId`",`"appName`":`"IPS`",`"loadScript`":true}"
 
 
        $RawContent = $AssetReq.RawContent -split "`n" | Select-String "PlatformTag|warrantyExpiringLabel"
        foreach($R in $RawContent){
            if($R -match "warrantyExpiringLabel.+>(.+)<\/p>"){
                $SupportDate = $Matches[1] -replace "`r"
            }
            elseif($R -match "PlatformTag = '(\w+)'"){
                $Tag = $Matches[1]
            }
        }
 
        $Props = [ordered]@{
            ServiceTag = $Tag
            Model = $Model
            'Support Date' = $SupportDate
        }
 
        New-Object -TypeName psobject -Property $Props
    }
}
