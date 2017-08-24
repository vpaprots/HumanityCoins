docker stop $(docker ps -a)
docker rm $(docker ps -a)
docker rmi $(docker images | grep dev-vp)
docker rmi $(docker images | grep dev-jdoe)
clear
echo "Current Docker images:"
docker images
echo
echo "Currently running containers(should be empty):"
docker ps -a
