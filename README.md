# BackupBot 🤖

[![License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Build Status](https://gitea.calahilstudios.com/api/badges/owner/backupbot/status.svg)](https://gitea.calahilstudios.com/owner/backupbot)
[![Gitea](https://img.shields.io/badge/Gitea-calahilstudios.com-609926?logo=gitea&logoColor=white)](https://gitea.calahilstudios.com)

> **Automated Docker backup system for PostgreSQL databases and application configurations with Duplicati integration**

BackupBot is a comprehensive backup solution that automatically discovers and backs up PostgreSQL containers, creates btrfs snapshots of your application data, and provides a web-based configuration interface. Built on top of LinuxServer.io's Duplicati image, it combines database backups with flexible cloud storage options.

---

## ✨ Features

- 🔍 **Auto-Discovery**: Automatically detects PostgreSQL containers by image patterns
- 📊 **Multi-Database Support**: Backs up all databases within each PostgreSQL container using `pg_dumpall`
- 📸 **Filesystem Snapshots**: Creates read-only btrfs snapshots of application data
- 🔄 **Automated Scheduling**: Configurable backup times with retry logic
- 🌐 **Web Interface**: Simple configuration UI accessible on port 8080
- 🔔 **Gotify Integration**: Optional push notifications for backup failures
- 🗄️ **Duplicati Integration**: Full access to Duplicati for cloud backup destinations
- 🧹 **Retention Management**: Automatic cleanup of old backups based on retention policy
- 🐳 **Docker-Native**: Designed to run in containerized environments

---

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Btrfs filesystem for snapshot functionality (optional but recommended)
- Running PostgreSQL containers you want to back up

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://gitea.calahilstudios.com/owner/backupbot.git
   cd backupbot
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   nano .env
   ```

3. **Start the container:**
   ```bash
   docker-compose up -d
   ```

4. **Access the interfaces:**
   - BackupBot Config: http://localhost:8201
   - Duplicati Web UI: http://localhost:8200

---

## 📋 Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Duplicati encryption key (required)
KEY=your_encryption_key_here

# Duplicati web password (required)
PASSWORD=your_secure_password

# User/Group IDs (optional)
PUID=1000
PGID=1000

# Timezone (optional)
TZ=America/Los_Angeles
```

### BackupBot Configuration

BackupBot settings are managed through the web interface at `http://localhost:8201` or via the config file at `/config/backupbot.conf`:

```bash
TZ=America/Los_Angeles
BACKUP_DIR=/backups/postgres
LOG_FILE=/config/log/pgbackup.log
MAX_RETRIES=3
GOTIFY_URL=http://gotify.example.com
GOTIFY_TOKEN=your_gotify_token_here
BACKUP_HOUR=03
BACKUP_MINUTE=00
RETENTION_DAYS=7
```

### Supported PostgreSQL Images

BackupBot automatically detects containers running these images:

- `postgres:17.0-alpine`
- `postgres:17`
- `postgres:14.0-alpine`
- `postgres` (any version)
- `ghcr.io/immich-app/postgres:*`

Additional patterns can be added by modifying the `KNOWN_IMAGES` list in `backup.sh`.

---

## 🗂️ Volume Mappings

```yaml
volumes:
  # Duplicati configuration
  - /srv/appdata/duplicati/config:/config
  
  # Backup storage (where dumps are stored)
  - /srv/backups:/backups:rshared
  
  # Docker socket (for container discovery)
  - /var/run/docker.sock:/var/run/docker.sock:ro
  
  # Source data for snapshots (optional)
  - /srv/appdata:/source/appdata:ro
```

---

## 🔧 Usage

### Manual Backup

Trigger a backup manually:

```bash
docker exec backupbot /usr/local/bin/backup.sh
```

### View Logs

Monitor backup operations:

```bash
docker logs -f backupbot
```

### Check Backup Files

Backups are organized by container name:

```bash
ls -lh /srv/backups/postgres_dumps/
```

Example structure:
```
/srv/backups/
├── postgres_dumps/
│   ├── myapp_db/
│   │   ├── 2024-10-23_03-00-00.sql
│   │   └── 2024-10-24_03-00-00.sql
│   └── another_db/
│       └── 2024-10-23_03-00-00.sql
└── snapshots/
    ├── hostname-2024-10-23/
    └── hostname-2024-10-24/
```

---

## 🎯 How It Works

1. **Discovery Phase**: BackupBot scans running Docker containers and identifies PostgreSQL instances
2. **Extraction**: For each database, credentials are extracted from environment variables
3. **Backup**: `pg_dumpall` creates a complete SQL dump of all databases
4. **Snapshot**: A read-only btrfs snapshot is created of `/srv/appdata`
5. **Retention**: Old backups exceeding the retention period are automatically deleted
6. **Notification**: On failure after retries, Gotify notifications are sent (if configured)

---

## 🔐 Security Notes

- **Privileged Mode**: Required for btrfs snapshot functionality
- **Docker Socket**: Read-only access needed for container discovery
- **Credentials**: Database passwords are extracted from container environment variables
- **Network**: BackupBot runs in bridge mode by default

### Best Practices

- Use strong encryption keys for Duplicati
- Restrict access to the web interfaces using a reverse proxy with authentication
- Regularly test backup restoration procedures
- Store encryption keys securely outside the container

---

## 🛠️ Development

### Building from Source

```bash
docker build -t backupbot:latest .
```

### CI/CD Pipeline

BackupBot uses Gitea Actions for automated builds:

- **Trigger**: Push to `main` or `develop` branches
- **Registry**: `gitea.calahilstudios.com`
- **Tags**: `develop` and commit SHA

---

## 📊 Monitoring

### Web Interfaces

- **BackupBot Config**: `http://localhost:8201`
  - Configure backup schedules
  - Set retention policies
  - Manage Gotify notifications

- **Duplicati**: `http://localhost:8200`
  - Configure cloud storage destinations
  - Schedule remote backups
  - Restore from backups

### Log Levels

Set via `BACKUPBOT_WEB_LOGGING` environment variable:
- `DEBUG`: Verbose logging with exception traces
- `INFO`: Standard operational logs (default)
- `WARN`: Warnings and errors only

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request on Gitea

---

## 📝 License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

**AGPL-3.0 Key Points:**
- ✅ Free to use, modify, and distribute
- ✅ Source code must be made available
- ✅ Network use is considered distribution
- ✅ Modifications must also be AGPL-3.0

---

## 🙏 Acknowledgments

- Built on [LinuxServer.io Duplicati](https://github.com/linuxserver/docker-duplicati)
- PostgreSQL backup functionality inspired by community best practices
- Web interface uses vanilla JavaScript for minimal dependencies

---

## 📞 Support

- 🐛 **Issues**: [Report bugs on Gitea](https://gitea.calahilstudios.com/owner/backupbot/issues)
- 📚 **Documentation**: This README and inline code comments
- 💬 **Discussions**: Open an issue for questions

---

## 🗺️ Roadmap

- [ ] MySQL/MariaDB support
- [ ] MongoDB backup integration
- [ ] Advanced scheduling options (multiple backup windows)
- [ ] Backup verification and integrity checks
- [ ] Prometheus metrics export
- [ ] Email notifications
- [ ] Backup compression options

---

**Made with ❤️ by Calahil Studios**

[![Gitea](https://img.shields.io/badge/View%20on-Gitea-609926?style=for-the-badge&logo=gitea&logoColor=white)](https://gitea.calahilstudios.com)
