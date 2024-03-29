//
//  Flickr-Constants.swift
//  Virtual Tourist
//
//  Created by KT on 7/22/15.
//  Copyright (c) 2015 Kinan Turman. All rights reserved.
//

import Foundation

extension Flickr {

    struct Constants {
        // MARK: - Constants
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "a41f5351c59d09b9c3d55580be4d9222"
    }
    
    struct Resources {
        // MARK: - Parameters
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let PER_PAGE = "21"
        static let LAT = "lat"
        static let LONG = "lon"
        static let RADIUS = "radius"
    }
    
    struct Values {
        // MARK: - Values
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        static let MAX_RESULTS = 4000
        static let RADIUS = 5
    }
}