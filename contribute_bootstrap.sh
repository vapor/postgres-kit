echo "💧  starting docker..."
docker-machine start default

echo "💧  exporting docker machine environment..."
eval $(docker-machine env default)

echo "💧  cleaning previous psql containers..."
docker stop vapor-psql
docker stop vapor-psql-ssl
docker rm vapor-psql
docker rm vapor-psql-ssl

echo "💧  creating vapor-psql dev db..."
docker run --name vapor-psql -e POSTGRES_USER=vapor_username -e POSTGRES_DB=vapor_database -p 5432:5432 -d postgres:latest

echo "💧  creating vapor-psql-ssl dev db..."
docker run -d --name vapor-psql-ssl -e POSTGRES_USER=vapor_username -e POSTGRES_DB=vapor_database -p 5433:5432 scenecheck/postgres-ssl:latest

echo "💧  generating xcode proj..."
swift package -Xswiftc -DTEST_DOCKER_HOSTNAME generate-xcodeproj

echo "💧  opening xcode..."
open *.xcodeproj
