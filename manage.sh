#!/bin/bash

# Plane.so Management Script
# 포트: 9000 ~ 9013 번대 사용

PROJECT_DIR="/Volumes/WorkSpace/0200_Dev/ANTIGRAVITY/PLANE.SO.GAEASOT"
PORTS=(9000 9001 9002 9003 9005 9006 9010 9011 9012 9013)

function check_and_kill_ports() {
    echo "🔍 포트 충돌 확인 중 (9000번대)..."
    for port in "${PORTS[@]}"; do
        pid=$(lsof -t -i:$port)
        if [ ! -z "$pid" ]; then
            echo "⚠️  포트 $port 사용 중 (PID: $pid). 강제 종료합니다."
            kill -9 $pid
        fi
    done
}

function backup_db() {
    echo "💾 데이터베이스 백업 생성 중..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$PROJECT_DIR/backups"
    mkdir -p $BACKUP_DIR
    docker exec plane-db pg_dump -U plane plane > "$BACKUP_DIR/plane_db_$TIMESTAMP.sql"
    echo "✅ 백업 완료: $BACKUP_DIR/plane_db_$TIMESTAMP.sql"
}

function update_cors_settings() {
    # .env 파일에서 현재 설정된 포트 읽기
    CURRENT_PORT=$(grep "LISTEN_HTTP_PORT=" .env | cut -d'=' -f2)
    echo "🌐 포트 $CURRENT_PORT 에 맞춰 CORS 설정 업데이트 중..."
    
    # OS X sed 호환성을 위해 임시 파일 사용
    sed -i '' "s|WEB_URL=.*|WEB_URL=\"http://localhost:$CURRENT_PORT\"|g" .env
    sed -i '' "s|CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=\"http://localhost:$CURRENT_PORT,http://127.0.0.1:$CURRENT_PORT\"|g" .env
}

case "$1" in
    start)
        check_and_kill_ports
        update_cors_settings
        echo "🚀 인프라 및 서비스 기동 (Optimized Build)..."
        export DOCKER_BUILDKIT=1
        docker-compose down
        docker-compose up -d --build
        echo "✨ 서비스가 9000번 포트에서 시작되었습니다."
        echo "- 메인 접속: http://localhost:9000"
        echo "- MinIO 콘솔: http://localhost:9006"
        ;;
    stop)
        echo "🛑 서비스 중단..."
        docker-compose stop
        ;;
    down)
        echo "🗑️ 컨테이너 제거..."
        docker-compose down
    ;;
    backup)
        backup_db
        ;;
    status)
        docker-compose ps
        ;;
    *)
        echo "사용법: $0 {start|stop|down|backup|status}"
        exit 1
esac
