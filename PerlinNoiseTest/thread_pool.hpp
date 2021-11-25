#pragma once
#include <thread>
#include <mutex>
#include <condition_variable>
#include <vector>
#include <queue>
#include <functional>

class Thread_pool
{
private:
	std::vector <std::thread> workers;
	std::queue <std::function<void()>> jobs;
	std::mutex jobs_mutex;
	std::condition_variable jobs_condition;
	std::condition_variable finished_condition;
	std::size_t busy_workers;
	bool active;

public:
	Thread_pool(const std::size_t& threadsNo);
	void AddJobABCS(std::function<void()> job);
	void WaitForAllJobs();
	~Thread_pool();
};

Thread_pool::Thread_pool(const std::size_t& threadsNo) : busy_workers(0)
{
	if (threadsNo == 0)
	{
		active = false;
		throw std::runtime_error("Can't create thread pool with 0 threads.\n");
	}
	for (std::size_t i = 0; i < threadsNo; ++i)
		workers.push_back(std::thread(
			[this]()
			{
				while (true)
				{
					std::unique_lock<std::mutex> jobs_lock(jobs_mutex);
					jobs_condition.wait(jobs_lock,
						[this]() {return !jobs.empty() || !active; });
					if (!active && jobs.empty())
						return;

					std::function<void()> currentJob = jobs.front();
					jobs.pop();
					++busy_workers;
					jobs_lock.unlock();
					currentJob();

					jobs_lock.lock();
					--busy_workers;
					jobs_lock.unlock();
					finished_condition.notify_one();

				}
			}
	));
	active = true;
}

void Thread_pool::AddJobABCS(std::function<void()> job)
{
	std::unique_lock<std::mutex> jobs_lock(jobs_mutex);
	jobs.push(job);
	jobs_lock.unlock();
	jobs_condition.notify_one();
}

void Thread_pool::WaitForAllJobs()
{
	std::unique_lock<std::mutex> jobs_lock(jobs_mutex);
	finished_condition.wait(jobs_lock,
		[this]()
		{return jobs.empty() && busy_workers == 0; }
	);
	jobs_lock.unlock();
}

Thread_pool::~Thread_pool()
{
	std::unique_lock<std::mutex> jobs_lock(jobs_mutex);
	active = false;
	jobs_lock.unlock();
	jobs_condition.notify_all();

	for (auto& worker : workers)
		worker.join();

}
