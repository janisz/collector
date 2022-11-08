import os, sys
import time, random
from subprocess import check_output
from subprocess import CalledProcessError

class PortProcess():
    def __init__(self, port, exec_path, action_file):
        self.port = port
        self.exec_path = exec_path
        self.action_file = action_file
        self.open = False

def waitForPod():
    time.sleep(10)
    while True:
        get_pod_cmd = "kubectl get pod"
        out = check_output(get_pod_cmd.split())
        ready = str(out).split('\\n')[1].split()[1]

        if ready == "1/1":
            break

        time.sleep(1)

def deployProcessesListeningOnPorts():
    deployment_name = "processes-listening-on-ports"
    try:
        delete_deployment_cmd = "kubectl delete deployment " + deployment_name
        out = check_output(delete_deployment_cmd.split())
        print(out)
    except CalledProcessError as e:
        print(e.output)

    try:
        delete_secret_cmd = "kubectl delete secret myregistrykey" 
        out = check_output(delete_secret_cmd.split())
        print(out)
    except CalledProcessError as e:
        print(e.output)

    secret_cmd = "kubectl create -f docker_registry_secret.yml" 
    deploy_cmd = "kubectl create -f deployment.yml"

    check_output(secret_cmd.split())
    check_output(deploy_cmd.split())

    waitForPod()

def getPod():
    get_pod_cmd = "kubectl get pod"
    out = check_output(get_pod_cmd.split())
    pod = str(out).split('\\n')[1].split()[0]

    return pod

def createProcesses(num_processes, image, container):
    processes = [("/process-listening-on-ports-" + str(i), "/tmp/action_file_" + str(i)) for i in range(num_processes)]

    deployProcessesListeningOnPorts()

    for process in processes:
        while True:
            try:
                pod = getPod()
                docker_copy_exec = "kubectl exec " + pod + " -- cp /process-listening-on-ports " + process[0]
                print(docker_copy_exec.split())
                check_output(docker_copy_exec.split())
                break
            except CalledProcessError as e:
                print(e.output)

        #start_process_cmd = "kubectl exec " + pod + " -c processes-listening-on-ports -- /bin/bash " + process[0] + " " + process[1] + " &"
        #start_process_cmd = "kubectl exec " + pod + " -c processes-listening-on-ports -- /bin/bash -c \"" + process[0] + " " + process[1] + " &" + '"'
        start_process_cmd = "kubectl exec " + pod + " -c processes-listening-on-ports -- " + process[0] + " " + process[1] + " &"
        print(start_process_cmd)
        os.system(start_process_cmd)

    return processes

def initializePorts(num_ports, processes):
    ports = [None] * num_ports
    for i in range(num_ports):
        idx = i % len(processes)
        ports[i] = PortProcess(i, processes[idx][0], processes[idx][1])

    return ports

def portAction(port, action, pod):
    #docker_cmd = "kubectl exec " + pod + " echo " + action + " " + str(port.port) 
    #docker_cmd += " > " + port.action_file
    #os.system(docker_cmd)
    #check_output(["kubectl", "exec", pod, "/bin/bash", "-c", "echo " + action + " " + str(port.port) + " > " + port.action_file])

    port_action_cmd = "kubectl exec " + pod + " -- /bin/bash -c \"echo " + action + " " + str(port.port) + " > " + port.action_file + '"'
    print(port_action_cmd)

    os.system(port_action_cmd)

def openAndClosePorts(ports, num_actions_per_second, container):
    waitForPod()
    pod = getPod()
    while True:
        time.sleep(1.0 / num_actions_per_second)
        randomPort = random.randint(0, len(ports) - 1)
        if ports[randomPort].open:
            portAction(ports[randomPort], "close", pod)
            ports[randomPort].open = False
        else:
            portAction(ports[randomPort], "open", pod)
            ports[randomPort].open = True

def main(num_processes, num_ports, num_actions_per_second, image, container):   
    print("Creating processes")
    processes = createProcesses(num_processes, image, container)
    print("Initializing ports")
    ports = initializePorts(num_ports, processes)
    print("Opening and closing ports")
    openAndClosePorts(ports, num_actions_per_second, container)

num_processes = 10
num_ports = 1000
num_actions_per_second = 10
container = "port-processes"
image = "quay.io/rhacs-eng/qa:collector-processes-listening-on-ports"
main(num_processes, num_ports, num_actions_per_second, image, container)
