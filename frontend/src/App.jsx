import { useEffect, useState } from 'react'
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
)

function App() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetchUsers()
  }, [])

  const fetchUsers = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase.from('users').select('*')
      if (error) throw error
      setUsers(data || [])
    } catch (err) {
      setError(err.message)
      console.error('Error fetching users:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-800">
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-4xl font-bold text-white mb-2">ExamEdge 📚</h1>
        <p className="text-slate-400 mb-8">Private NEET & JEE Test Platform</p>
        
        {loading && (
          <div className="text-center text-slate-400">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
            <p className="mt-4">Loading...</p>
          </div>
        )}
        
        {error && (
          <div className="bg-red-500/20 border border-red-500 rounded-lg p-4 text-red-200 mb-4">
            <p className="font-semibold">Error:</p>
            <p>{error}</p>
            <p className="text-sm mt-2">Check your .env.local file and Supabase connection</p>
          </div>
        )}
        
        {!loading && !error && (
          <div className="bg-slate-800 rounded-lg p-6 border border-slate-700">
            <h2 className="text-2xl font-semibold text-white mb-4">✅ Connection Successful!</h2>
            <p className="text-slate-300 mb-4">
              Your Supabase database is connected. Found <span className="font-bold text-blue-400">{users.length}</span> users.
            </p>
            
            <div className="overflow-x-auto">
              <table className="w-full text-left text-slate-300 text-sm">
                <thead className="border-b border-slate-600">
                  <tr>
                    <th className="px-4 py-2">Name</th>
                    <th className="px-4 py-2">Email</th>
                    <th className="px-4 py-2">Exam Type</th>
                    <th className="px-4 py-2">Role</th>
                    <th className="px-4 py-2">Points</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user) => (
                    <tr key={user.id} className="border-b border-slate-700 hover:bg-slate-700/50">
                      <td className="px-4 py-2">{user.name}</td>
                      <td className="px-4 py-2 text-slate-400">{user.email}</td>
                      <td className="px-4 py-2">
                        <span className={`px-2 py-1 rounded text-xs font-semibold ${
                          user.exam_type === 'NEET' ? 'bg-green-500/20 text-green-300' :
                          user.exam_type === 'JEE' ? 'bg-purple-500/20 text-purple-300' :
                          'bg-blue-500/20 text-blue-300'
                        }`}>
                          {user.exam_type}
                        </span>
                      </td>
                      <td className="px-4 py-2 capitalize">{user.role}</td>
                      <td className="px-4 py-2 font-semibold">{user.total_points || 0}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            
            <div className="mt-6 p-4 bg-slate-700/50 rounded border border-slate-600">
              <p className="text-slate-300 text-sm">
                <span className="font-semibold">🎉 Next Steps:</span>
              </p>
              <ul className="text-slate-400 text-sm mt-2 list-disc list-inside space-y-1">
                <li>Customize the UI components</li>
                <li>Implement authentication</li>
                <li>Build the test-taking interface</li>
                <li>Add analytics dashboard</li>
              </ul>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default App
