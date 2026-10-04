servers = ["web-01", "web-02", "web-03"]  # a list
config = {"port": 8080, "tls": True}      # a dictionary
zones = ("zone-a", "zone-b")             # a tuple
seen = {"web-01", "web-01", "web-02"}    # a set

print("First server:", servers[0])
print("Port:", config["port"])
print("Zones:", zones)
print("Unique servers:", seen)

for server in servers:
    print("Checking", server)

servers.append("web-04")
print("Server count:", len(servers))