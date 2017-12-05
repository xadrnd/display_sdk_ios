//
//  XADMRAIDUtil.swift
//  XADMRAID
//
//  Created by Phillip Corrigan on 7/6/16.
//  Copyright © 2016 xAd, Inc. All rights reserved.
//

import Foundation
import WebKit


class XADMRAIDUtil {
    class func processRawHtml(_ rawHtml: String) -> String?
    {
        var processedHtml = rawHtml
        
        // Remove the mraid.js script tag.
        // We expect the tag to look like this:
        // <script src='mraid.js'></script>
        // But we should also be to handle additional attributes and whitespace like this:
        // <script  type = 'text/javascript'  src = 'mraid.js' > </script>
        
        var pattern = "<script\\s+[^>]*\\bsrc\\s*=\\s*([\\\"\\\'])mraid\\.js\\1[^>]*>\\s*</script>\\n*"
        
        //above pattern is valid RG pattern, it's safe to force try
        var regex = try! NSRegularExpression(pattern: pattern,
                                             options: NSRegularExpression.Options.caseInsensitive)
        processedHtml = regex.stringByReplacingMatches(in: processedHtml,
            options: NSRegularExpression.MatchingOptions(rawValue: 0),
            range: NSMakeRange(0, processedHtml.characters.count),
            withTemplate: "")
        // Add html, head, and/or body tags as needed.
        let hasHtmlTag = rawHtml.range(of: "<html") != nil
        let hasHeadTag = rawHtml.range(of: "<head") != nil
        let hasBodyTag = rawHtml.range(of: "<body") != nil
        
        // basic sanity checks
        if ((!hasHtmlTag && (hasHeadTag || hasBodyTag)) ||
            (hasHtmlTag && !hasBodyTag)) {
            return nil
        }
        
        if !hasHtmlTag {
            processedHtml =
                "<html>\n" +
                "<head>\n" +
                "</head>\n" +
                "<body>\n" +
                "<div align='center'>\n" +
                "\(processedHtml)" +
                "</div>\n" +
                "</body>\n" +
                "</html>"
        } else if !hasHeadTag {
            // html tag exists, head tag doesn't, so add it
            pattern = "<html[^>]*>"
            regex = try! NSRegularExpression(pattern: pattern,
                                             options: NSRegularExpression.Options.caseInsensitive)
            processedHtml = regex.stringByReplacingMatches(in: processedHtml,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSMakeRange(0, processedHtml.characters.count),
                withTemplate: "$0\n<head>\n</head>")
        }
        
        // Add meta and style tags to head tag.
        let metaTag =
        "<meta name='viewport' content='width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no' />"
        
        let styleTag =
        "<style>\n" +
        "body { margin:0; padding:0; }\n" +
        "*:not(input) { -webkit-touch-callout:none; -webkit-user-select:none; -webkit-text-size-adjust:none; }\n" +
        "</style>"
        
        pattern = "<head[^>]*>";
        regex = try! NSRegularExpression(pattern: pattern,
                                         options: NSRegularExpression.Options.caseInsensitive)
        processedHtml = regex.stringByReplacingMatches(in: processedHtml,
               options: NSRegularExpression.MatchingOptions(rawValue: 0),
               range: NSMakeRange(0, processedHtml.characters.count),
               withTemplate: "$0\n\(metaTag)\n\(styleTag)")

        return processedHtml
    }
    
    class func synced(_ lock: AnyObject, closure:() -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
}

extension WKNavigationType {
    func stringDescription() -> String {
        switch self {
        case .linkActivated:
            return "linkActivated"
        case .other:
            return "other"
        case .backForward:
            return "backForward"
        case .formSubmitted:
            return "formSubmitted"
        case .formResubmitted:
            return "formResubmitted"
        case .reload:
            return "reload"
        }
    }
}
