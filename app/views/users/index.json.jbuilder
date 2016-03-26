json.array!(@users) do |user|
  json.extract! user, :id
  json.extract! user, :weibo_uid
end
