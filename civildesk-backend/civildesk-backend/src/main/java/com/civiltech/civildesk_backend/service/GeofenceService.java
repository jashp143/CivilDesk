package com.civiltech.civildesk_backend.service;

import com.civiltech.civildesk_backend.model.Site;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class GeofenceService {

    private static final double EARTH_RADIUS_METERS = 6371000;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Calculate distance between two GPS coordinates using Haversine formula
     * @return distance in meters
     */
    public double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
        
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return EARTH_RADIUS_METERS * c;
    }

    /**
     * Check if a point is inside the site's geofence
     */
    public boolean isInsideGeofence(Site site, double latitude, double longitude) {
        if (site.getGeofenceType() == Site.GeofenceType.POLYGON) {
            return isInsidePolygon(site.getGeofencePolygon(), latitude, longitude);
        } else {
            // Default to radius-based geofence
            double distance = calculateDistance(
                    site.getLatitude(), site.getLongitude(),
                    latitude, longitude
            );
            return distance <= site.getGeofenceRadiusMeters();
        }
    }

    /**
     * Calculate distance from site center
     */
    public double getDistanceFromSite(Site site, double latitude, double longitude) {
        return calculateDistance(site.getLatitude(), site.getLongitude(), latitude, longitude);
    }

    /**
     * Check if point is inside a polygon using Ray Casting algorithm
     * Polygon is stored as JSON array: [[lat1,lon1],[lat2,lon2],...]
     */
    @SuppressWarnings("unchecked")
    private boolean isInsidePolygon(String polygonJson, double latitude, double longitude) {
        if (polygonJson == null || polygonJson.isEmpty()) {
            return false;
        }

        try {
            List<List<Double>> polygon = objectMapper.readValue(polygonJson, List.class);
            
            if (polygon.size() < 3) {
                return false;
            }

            int n = polygon.size();
            boolean inside = false;

            for (int i = 0, j = n - 1; i < n; j = i++) {
                List<Double> pointI = polygon.get(i);
                List<Double> pointJ = polygon.get(j);
                
                double xi = pointI.get(0);
                double yi = pointI.get(1);
                double xj = pointJ.get(0);
                double yj = pointJ.get(1);

                if (((yi > longitude) != (yj > longitude)) &&
                    (latitude < (xj - xi) * (longitude - yi) / (yj - yi) + xi)) {
                    inside = !inside;
                }
            }

            return inside;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Validate GPS coordinates
     */
    public boolean isValidCoordinates(double latitude, double longitude) {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
    }

    /**
     * Get bounding box for nearby site search (approximate)
     * @param latitude center latitude
     * @param longitude center longitude
     * @param radiusMeters search radius in meters
     * @return Map with minLat, maxLat, minLon, maxLon
     */
    public Map<String, Double> getBoundingBox(double latitude, double longitude, double radiusMeters) {
        double latDelta = radiusMeters / 111000.0; // Approximate degrees per meter at equator
        double lonDelta = radiusMeters / (111000.0 * Math.cos(Math.toRadians(latitude)));

        return Map.of(
                "minLat", latitude - latDelta,
                "maxLat", latitude + latDelta,
                "minLon", longitude - lonDelta,
                "maxLon", longitude + lonDelta
        );
    }
}

