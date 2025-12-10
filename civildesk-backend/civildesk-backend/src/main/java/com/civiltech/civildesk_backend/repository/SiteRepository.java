package com.civiltech.civildesk_backend.repository;

import com.civiltech.civildesk_backend.model.Site;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SiteRepository extends JpaRepository<Site, Long> {

    Optional<Site> findBySiteCode(String siteCode);

    List<Site> findByIsActiveTrue();

    Page<Site> findByIsActive(Boolean isActive, Pageable pageable);

    @Query("SELECT s FROM Site s WHERE s.isActive = true AND " +
           "(:search IS NULL OR LOWER(s.siteName) LIKE LOWER(CONCAT('%', :search, '%')) " +
           "OR LOWER(s.siteCode) LIKE LOWER(CONCAT('%', :search, '%')) " +
           "OR LOWER(s.city) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<Site> searchSites(@Param("search") String search, Pageable pageable);

    @Query("SELECT s FROM Site s WHERE s.isActive = true AND " +
           "(:city IS NULL OR s.city = :city) AND " +
           "(:state IS NULL OR s.state = :state)")
    List<Site> findByFilters(@Param("city") String city, @Param("state") String state);

    // Find sites within a bounding box (for nearby sites search)
    @Query("SELECT s FROM Site s WHERE s.isActive = true AND " +
           "s.latitude BETWEEN :minLat AND :maxLat AND " +
           "s.longitude BETWEEN :minLon AND :maxLon")
    List<Site> findSitesInBoundingBox(
            @Param("minLat") Double minLat,
            @Param("maxLat") Double maxLat,
            @Param("minLon") Double minLon,
            @Param("maxLon") Double maxLon);

    boolean existsBySiteCode(String siteCode);
}

