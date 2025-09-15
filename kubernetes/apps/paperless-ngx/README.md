# Paperless-ngx Document Management System

A powerful, modern document management system designed to help organize and search through scanned documents with OCR, automatic tagging, and full-text search.

## Components

### Application Stack
- **Paperless-ngx**: Main document management application
- **PostgreSQL 15**: Database for metadata and search indices
- **Redis 7**: Task queue and caching
- **Apache Tika**: Document content extraction and parsing
- **Gotenberg**: PDF generation and document conversion

### Storage
- **Documents**: 100GB for processed documents and metadata
- **Media**: 50GB for original scanned files
- **Export**: 20GB for document exports and backups
- **Consume**: 10GB for incoming documents to be processed
- **Database**: 10GB for PostgreSQL data

## Access Information

### Web Interface
- **URL**: https://paperless.k8s.dttesting.com
- **Username**: admin
- **Password**: admin123! (change after first login)
- **Email**: admin@example.com

### Features Enabled
- **OCR Languages**: English, French, Spanish, German
- **Auto-tagging**: Subdirectories become tags automatically
- **Document Format**: `{year}/{correspondent}/{title}`
- **Task Workers**: 2 workers with 2 threads each for parallel processing
- **Consumer Polling**: Every 60 seconds for new documents

## Document Processing

### Upload Methods
1. **Web Upload**: Drag and drop files in the web interface
2. **Consume Folder**: Place files in `/consume` directory
3. **Email**: Configure email consumption (requires additional setup)
4. **API**: RESTful API for programmatic uploads

### Supported Formats
- **PDFs**: Native PDF processing with OCR for scanned PDFs
- **Images**: JPEG, PNG, TIFF, WebP with OCR
- **Office Documents**: DOCX, XLSX, PPTX via Tika
- **Text Files**: TXT, RTF, HTML
- **Email**: EML and MSG files

### Processing Pipeline
1. **Document Intake**: Files detected in consume folder
2. **Content Extraction**: Apache Tika extracts text and metadata
3. **OCR Processing**: Tesseract performs OCR on images and scanned PDFs
4. **Classification**: Automatic document type detection
5. **Tagging**: Rules-based and ML-powered tag assignment
6. **Storage**: Processed files moved to organized structure

## Configuration

### Environment Variables
```yaml
# Database
PAPERLESS_DBHOST: postgres
PAPERLESS_DBNAME: paperless

# Redis Cache
PAPERLESS_REDIS: redis://redis:6379

# Document Processing
PAPERLESS_OCR_LANGUAGE: eng
PAPERLESS_OCR_LANGUAGES: eng fra spa deu
PAPERLESS_CONSUMER_POLLING: 60
PAPERLESS_CONSUMER_RECURSIVE: true

# File Organization
PAPERLESS_FILENAME_FORMAT: "{created_year}/{correspondent}/{title}"
PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS: true
```

### Performance Tuning
- **Task Workers**: 2 workers for parallel document processing
- **Threads per Worker**: 2 threads per worker
- **Memory Allocation**: 3GB limit for main container
- **CPU Allocation**: 2 CPU cores for intensive OCR processing

## Document Organization

### Automatic Filing
Documents are automatically organized by:
- **Year**: Based on document creation date
- **Correspondent**: Sender or source organization
- **Title**: Extracted or assigned document title

### Tagging System
- **Automatic Tags**: Based on content analysis
- **Folder Tags**: Subdirectories in consume folder become tags
- **Manual Tags**: User-defined tags for custom organization
- **ML Tags**: Machine learning suggestions based on content

### Search Capabilities
- **Full-text Search**: Search within document content
- **Metadata Search**: Filter by date, correspondent, tags
- **Boolean Operators**: AND, OR, NOT for complex queries
- **Saved Searches**: Store frequently used search queries

## Backup and Recovery

### Data Backup
```bash
# Backup document data
kubectl exec -n paperless deployment/paperless-ngx -- tar -czf - /usr/src/paperless/data > paperless-data-backup.tar.gz

# Backup media files
kubectl exec -n paperless deployment/paperless-ngx -- tar -czf - /usr/src/paperless/media > paperless-media-backup.tar.gz

# Backup database
kubectl exec -n paperless deployment/postgres -- pg_dump -U paperless paperless > paperless-db-backup.sql
```

### Document Export
- **Bulk Export**: Export all documents with metadata
- **Selective Export**: Export by tags, dates, or search criteria
- **Format Options**: Original files, PDFs, or zip archives
- **Metadata Export**: JSON or CSV format for document metadata

## Security Features

### Access Control
- **User Authentication**: Local user accounts with password protection
- **Permission Groups**: Read-only, editors, and admin roles
- **Document Permissions**: Per-document access control
- **API Authentication**: Token-based API access

### Data Protection
- **HTTPS**: Encrypted communication via Traefik
- **Database Encryption**: Encrypted database connections
- **File Permissions**: Proper filesystem permissions
- **Backup Encryption**: Encrypted backup storage recommended

## Integration and API

### REST API
- **Document CRUD**: Create, read, update, delete documents
- **Search API**: Programmatic search functionality
- **Metadata API**: Access to tags, correspondents, document types
- **Bulk Operations**: Mass import/export capabilities

### Webhook Support
- **Document Events**: Notifications on document processing
- **Custom Integrations**: Trigger external workflows
- **Email Notifications**: Optional email alerts for events

## Troubleshooting

### Common Issues

#### Documents Not Processing
```bash
# Check consume folder permissions
kubectl exec -n paperless deployment/paperless-ngx -- ls -la /usr/src/paperless/consume

# Check processing logs
kubectl logs -n paperless deployment/paperless-ngx -c paperless -f

# Restart document consumer
kubectl rollout restart deployment/paperless-ngx -n paperless
```

#### OCR Issues
```bash
# Check OCR language installation
kubectl exec -n paperless deployment/paperless-ngx -- tesseract --list-langs

# Test OCR on sample document
kubectl exec -n paperless deployment/paperless-ngx -- tesseract /path/to/test.png stdout
```

#### Database Connection Problems
```bash
# Check PostgreSQL status
kubectl get pods -n paperless -l app.kubernetes.io/name=postgres

# Test database connection
kubectl exec -n paperless deployment/postgres -- pg_isready -U paperless
```

#### Performance Issues
```bash
# Check resource usage
kubectl top pods -n paperless

# Monitor processing queue
kubectl logs -n paperless deployment/paperless-ngx -c paperless | grep "Task"

# Scale resources if needed
kubectl patch deployment paperless-ngx -n paperless -p '{"spec":{"template":{"spec":{"containers":[{"name":"paperless","resources":{"limits":{"cpu":"4000m","memory":"4Gi"}}}]}}}}'
```

### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n paperless

# Check disk usage
kubectl exec -n paperless deployment/paperless-ngx -- df -h

# Clean old temporary files
kubectl exec -n paperless deployment/paperless-ngx -- find /tmp -type f -mtime +7 -delete
```

## Best Practices

### Document Management
1. **Consistent Naming**: Use descriptive filenames before upload
2. **Folder Organization**: Organize consume folders by document type
3. **Regular Cleanup**: Periodically review and clean up tags
4. **Backup Schedule**: Implement regular automated backups

### Performance Optimization
1. **Resource Monitoring**: Monitor CPU and memory usage
2. **Queue Management**: Avoid large batch uploads during peak times
3. **Storage Management**: Regularly archive old documents
4. **Index Optimization**: Rebuild search index periodically

### Security Maintenance
1. **Password Rotation**: Change default passwords immediately
2. **User Management**: Regular review of user accounts and permissions
3. **Update Schedule**: Keep Paperless-ngx updated to latest version
4. **Access Logging**: Monitor access logs for suspicious activity

This document management system provides a comprehensive solution for digitizing, organizing, and searching through physical documents with advanced OCR and automated classification capabilities.